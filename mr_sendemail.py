#!/usr/bin/env python3

import smtplib, json, argparse, os, stat, time, base64, subprocess, socket, uuid
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from email.utils import formatdate
from email import message_from_string
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials

##### V 0.15
##### Stand alone script to send email via Truenas

def validate_arguments(args):
    """
        new function for an easier validation of the args passed to the function, due the fact there are now 2 calls methods. If mail_body_html is passed, nor subject and to_address are mandatory
    """
    if not args.mail_bulk and not args.mail_body_html:
        print("Error: You must provide at least --mail_bulk or --mail_body_html.")
        exit(1)
    if args.mail_body_html and (not args.subject or not args.to_address):
        print("Error: If --mail_body_html is provided, both --subject and --to_address are required.")
        exit(1)
    if not os.access(os.getcwd(), os.W_OK):
        print(f"Current user doesn't have permission in the execution folder: {os.getcwd()}")
        exit(1)     
    sfw = is_secure_directory()
    if sfw:
        print(f"{sfw}")
        
def is_secure_directory(directory_to_check=None):
    """
        this function help to report eventually security concerns about the usage context of the script. Promemorial: The function itself not log anything, output should be used when logfile available
    """
    try:
        directory_to_check = directory_to_check or os.getcwd()
        stat_info  = os.stat(directory_to_check)
        append_message = ""
        if stat_info .st_uid != os.getuid():
            append_message = f"Security Advice: The current user (UID={os.getuid()}) is not the owner of the directory '{directory_to_check}' (Owner UID={stat_info .st_uid})."
        if bool(stat_info .st_mode & stat.S_IWOTH):
            append_message = append_message + "SECURITY WARNING: this folder is accessible to non-priviliged users that are nor owner or in group"
        return append_message  
    except Exception as e:
        print(f"Something wrong checking security issue: {e} checking {directory_to_check}")
        exit(1)          

def create_log_file():
    """
        We setup a folder called sendemail_log where store log's file on every start. Every Logfiles can be safely deleted, but the script itself will only retain just the newest 15.
        Starting from 0.13 sendemail_log folder will be forced to 700 and log files to 600. Also symlinks will be ignored
    """   
    try:    
        log_dir = os.path.join(os.getcwd(), 'sendemail_log')
        
        if os.path.islink(log_dir):
            print("Something wrong is happening here: the sendemail_log folder is a symlink")
            exit(1)  
        
        if not os.path.exists(log_dir):
            os.makedirs(log_dir)
            try:
                os.chmod(log_dir, 0o700)
            except Exception as e:
                print(f"Can't apply permission to log folder {e}")
            log_file_count = 0
        else:    
            current_log_dir_permissions = stat.S_IMODE(os.stat(log_dir).st_mode)
            if current_log_dir_permissions != 0o700:
                try:
                    os.chmod(log_dir, 0o700)
                except Exception as e:
                    print(f"Can't apply permission to log folder {e}")
                
            log_files = [f for f in os.listdir(log_dir) if f.endswith('.txt') and os.path.isfile(os.path.join(log_dir, f)) and not os.path.islink(os.path.join(log_dir, f))]
            log_file_count = len( log_files )
            if log_file_count >= 15:
                oldest_file = min(log_files, key=lambda f: os.path.getctime(os.path.join(log_dir, f)))   
                os.remove(os.path.join(log_dir, oldest_file))         

        timestamp = time.strftime("%Y%m%d_%H%M%S", time.localtime())
        log_file_path = os.path.join(log_dir, f"{timestamp}.txt")

        if not os.path.exists(log_file_path):
            with open(log_file_path, 'w') as f:
                pass
            try:
                os.chmod(log_file_path, 0o600)
            except Exception as e:
                print(f"Can't apply permission to log file {e}")                
        return log_file_path, log_file_count
    except Exception as e:
        print(f"Something wrong managing logs: {e}")
        exit(1)          

def append_log(content):
    """
        Centralized file log append
    """      
    try:
        with open(log_file, 'a') as f:
            f.write(content + '\n')
    except Exception as e:
        process_output(True, f"Error: {e}", 1)

def process_output(error, detail="", exit_code=None):
    """
        Centralized output response 
        - error bool detail string exit_code 0 (ok) 1 (ko) or None (ignore)
    """                   
    response = json.dumps({"error": error, "detail": detail, "logfile": log_file, "total_attach": attachment_count, "ok_attach": attachment_ok_count}, ensure_ascii=False)
    append_log(f"{detail}") 
    print(response)
    if exit_code is not None:
        exit(exit_code)

def read_config_data():
    """
     function for read the mail.config from midclt 
    """    
    append_log("trying read mail.config") 
    midclt_output = subprocess.run(
        ["/usr/bin/midclt", "call", "mail.config"],
        capture_output=True,
        text=True,
        check=True
    )
    if midclt_output.returncode != 0:
        process_output(True, f"Failed to call midclt: {midclt_output.stderr.strip()}", 1)
        
    append_log("read mail.config successfully")                
    midclt_config = json.loads(midclt_output.stdout)
    return midclt_config

def load_html_content(input_content):
    """
     use this fuction to switch from achieve nor a file to read and a plain text/html
    """
    try:        
        if len(input_content) > 255:
            append_log("body can't be a file, too much long")
            return input_content
        elif os.path.exists(input_content):
            with open(input_content, 'r') as f:
                append_log("body is a file") 
                return f.read()
        else:
            append_log("no file found, plain text/html output") 
            return input_content            
    except Exception as e:
        process_output(True, f"Something wrong on body content {e}", 1)  

def validate_base64_content(input_content):
    """
    use this funtcion to validate that an input is base64encoded. Return error if not
    """      
    try:
        base64.b64decode(input_content, validate=True) 
        append_log("Base64 message is valid.")
    except Exception as e:
        process_output(True, f"Error: Invalid Base64 content. {e}", 1)   
                            
def calc_attachment_count(attachment_input):      
    """
    improved attachments output
    """      
    total_attachments = len(attachment_input) if attachment_input else 0
    return total_attachments    

def attach_files(msg, attachment_files, attachment_ok_count):
    """
    Function to attach files!
    """
    for attachment_file in attachment_files:
        try:
            with open(attachment_file, 'rb') as f:
                file_data = f.read()              
                part = MIMEBase('application', 'octet-stream')
                part.set_payload(file_data)
                encoders.encode_base64(part)
                part.add_header(
                    'Content-Disposition',
                    f'attachment; filename="{attachment_file.split("/")[-1]}"'
                )
                msg.attach(part)
                attachment_ok_count +=1
                append_log(f"OK {attachment_file}")
        
        except Exception as e:
            append_log(f"KO {attachment_file}: {e}")      
    return attachment_ok_count  

def getMRconfigvalue(key):
    """
    Function to get eventually multi report value from config, passing the key > the name of the setting
    """    
    config_file = "multi_report_config.txt" 
    
    if not os.path.exists(config_file):
        append_log(f"{config_file} not found")
        return ""

    try:
        with open(config_file, "r") as file:
            for line in file:
                line = line.strip()
                key_value_pair, _, _ = line.partition('#')
                key_value_pair = key_value_pair.strip()

                if key_value_pair.startswith(key + "="):
                    append_log(f"{key} found")
                    value = key_value_pair.split("=")[1].strip().strip('"')
                    return value
    except Exception as e:
        append_log(f"{config_file} not found. {e}")
        return ""

    return ""
            
def send_email(subject, to_address, mail_body_html, attachment_files, email_config, provider, bulk_email):
    """
    Function to send an email via SMTP or Gmail OAuth based on the provider available
    """
    attachment_ok_count = 0  
    if provider == "smtp":
        try:
            append_log("parsing smtp config") 
            smtp_security = email_config["security"]
            smtp_server = email_config["outgoingserver"]
            smtp_port = email_config["port"]
            smtp_user = email_config["user"]
            smtp_password = email_config["pass"]
            smtp_fromemail = email_config["fromemail"]
            smtp_fromname = email_config["fromname"]
            smtp_login = email_config["smtp"]
            
            append_log("switch from classic send and bulk email")    
            if mail_body_html:
                append_log("mail hmtl provided")
                append_log("parsing html content") 
                html_content = load_html_content(mail_body_html)

                append_log("start parsing headers")
                msg = MIMEMultipart()
                append_log("parsing data from config") 
                if smtp_fromname:
                    msg['From'] = f"{smtp_fromname} <{smtp_fromemail}>"
                    append_log(f"using fromname {smtp_fromname}")
                else: 
                    msg['From'] = smtp_fromemail
                    append_log(f"using fromemail {smtp_fromemail}")
                msg['To'] = to_address
                msg['Subject'] = subject
                msg.attach(MIMEText(html_content, 'html'))
                
                append_log(f"generate a message ID using {smtp_user}")
                try:
                    messageid_domain = smtp_user.split("@")[1]
                except Exception:
                    append_log(f"{smtp_user} not a valid address, tryng on {smtp_fromemail}")
                    try:
                        messageid_domain = smtp_fromemail.split("@")[1]
                    except Exception:
                        append_log(f"{smtp_fromemail} not a valid address, need to use a fallback ")
                        messageid_domain = "local.me"
                append_log(f"domain: {messageid_domain}")
                messageid_uuid = f"{datetime.now().strftime('%Y_%m_%d_%H_%M_%S_%f')[:-3]}{uuid.uuid4()}"
                append_log(f"uuid: {messageid_uuid}")
                messageid = f"<{messageid_uuid}@{messageid_domain}>"
                append_log(f"messageid: {messageid}")
                msg['Message-ID'] = messageid
                msg['Date'] = formatdate(localtime=True) #
                
                
                append_log("check for attachements...") 
                if attachment_files:
                    append_log("attachments found") 
                    attachment_ok_count = attach_files(msg, attachment_files, attachment_ok_count)
                    append_log(f"{attachment_ok_count} ok attachments") 
                    
                append_log("get hostname")     
                hostname = socket.getfqdn()
                if not hostname:
                    hostname = socket.gethostname()  
                append_log(f"hostname retrieved: {hostname}")   
            
            elif bulk_email:
                append_log("using bulk email provided")
                hostname = ""
                pre_msg = load_html_content(bulk_email)
                if not pre_msg:
                    append_log("can't properly retrieve bulk email")
                validate_base64_content(pre_msg) 
                try:
                    decoded_msg = base64.b64decode(pre_msg).decode('utf-8')
                    append_log("bulk email successfully decoded from Base64")
                    mime_msg = message_from_string(decoded_msg)
                    to_address = mime_msg['To']
                    if to_address:
                        append_log("recipient retrieved")
                        msg = mime_msg
                    else:
                        process_output(True, "failed retriving recipient", 1)    
                except Exception as e:
                    process_output(True, f"Error decoding Base64 content: {e}", 1)                
                 
            else:
                process_output(True, "Something wrong with the data input", 1)

            append_log(f"establing connection based on security level set on TN: {smtp_security}") 
            if smtp_security == "TLS":
                with smtplib.SMTP(smtp_server, smtp_port) as server:
                    append_log(f"entered {smtp_security} path")                        
                    if hostname:        
                        append_log("adding ehlo to the message")          
                        server.ehlo(hostname)      
                    append_log("establing TLS connection")    
                    server.starttls()
                    if smtp_login:
                        append_log("entering credentials") 
                        server.login(smtp_user, smtp_password)
                    else:
                        smtp_user = smtp_fromemail
                        append_log(f"smtp set to {smtp_login}")
                    append_log(f"sending {smtp_security} email") 
                    server.sendmail(smtp_user, to_address, msg.as_string())
            elif smtp_security == "SSL":
                with smtplib.SMTP_SSL(smtp_server, smtp_port) as server:
                    append_log(f"entered {smtp_security} path")   
                    if hostname:        
                        append_log("adding ehlo to the message")          
                        server.ehlo(hostname)   
                    if smtp_login:           
                        append_log("entering credentials") 
                        server.login(smtp_user, smtp_password)
                    else:
                        smtp_user = smtp_fromemail
                        append_log(f"smtp set to {smtp_login}")
                    append_log(f"sending {smtp_security} email") 
                    server.sendmail(smtp_user, to_address, msg.as_string())
            elif smtp_security == "PLAIN":
                with smtplib.SMTP(smtp_server, smtp_port) as server:
                    append_log(f"entered {smtp_security} path")   
                    if hostname:        
                        append_log("adding ehlo to the message")          
                        server.ehlo(hostname)  
                    if smtp_login:    
                        append_log("entering credentials")
                        server.login(smtp_user, smtp_password)
                    else:
                        smtp_user = smtp_fromemail
                        append_log(f"smtp set to {smtp_login}")    
                    append_log(f"sending {smtp_security} email") 
                    server.sendmail(smtp_user, to_address, msg.as_string())        
            else:
                process_output(True, "KO: something wrong switching SMTP security level", 1)             

            append_log("Email Sent via SMTP")

        except Exception as e:
            process_output(True, f"KO: {e}", 1)

    elif provider == "gmail": 
        try:
            append_log("parsing Oauth config") 
            credentials = Credentials.from_authorized_user_info(email_config["oauth"])
            service = build('gmail', 'v1', credentials=credentials)
            
            append_log("switch from classic send and bulk email")     
            if mail_body_html:                  
                append_log("mail hmtl provided")
                append_log("start parsing headers")          
                msg = MIMEMultipart()
                append_log("parsing data from config") 
                fallback_fromname = getMRconfigvalue("FromName")
                fallback_fromemail = getMRconfigvalue("From")
                
                if fallback_fromname and fallback_fromemail:
                    msg['From'] = f"{fallback_fromname} <{fallback_fromemail}>"
                    append_log("using fallback fromname") 
                elif fallback_fromemail: 
                    msg['From'] = fallback_fromemail
                    append_log("using fallback fromemail")         
                else:
                    append_log("can't find a from setting. Gmail will apply the default")  
                    
                msg['to'] = to_address
                msg['subject'] = subject
                        
                append_log("parsing html content") 
                html_content = load_html_content(mail_body_html)            
                msg.attach(MIMEText(html_content, 'html'))
                
                append_log("check for attachements...") 
                if attachment_files:
                    append_log("attachments found") 
                    attachment_ok_count = attach_files(msg, attachment_files, attachment_ok_count)
                    append_log(f"{attachment_ok_count} ok attachments")   
                      
                append_log("Encoding message")     
                raw_message = msg.as_bytes() 
                msg = base64.urlsafe_b64encode(raw_message).decode('utf-8')                
                    
            elif bulk_email:
                append_log("using bulk email provided")
                msg = load_html_content(bulk_email)
                validate_base64_content(msg)          
            else:
                process_output(True, "Something wrong with the data input", 1)                                                     
            
            append_log("sending email")           
            service.users().messages().send(userId="me", body={'raw': msg}).execute()
            
            append_log("Email Sent via Gmail")
            return attachment_ok_count

        except Exception as e:
            process_output(True, f"KO: {e}", 1)

    else:
        process_output(True, "No valid email configuration found.", 1)
                                
  
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Workaround to send email easily in Multi Report using Truenas mail.config")
    parser.add_argument("--subject", help="Email subject. Mandatory when using -mail_body_html")
    parser.add_argument("--to_address", help="Recipient email address. Mandatory when using -mail_body_html")
    parser.add_argument("--mail_body_html", help="File path for the email body, or just a plain text/html. No encoding needed")
    parser.add_argument("--attachment_files", nargs='*', help="OPTIONAL attachments as json file path array. No ecoding needed")
    parser.add_argument("--mail_bulk", help="Bulk email with all necessary parts, encoded and combined together. File path or plain text supported. Content must be served as Base64 without newline /n, the recipient will be get from the To in the message")

    args = parser.parse_args()
    
    validate_arguments(args) 

    try:
        attachment_count = calc_attachment_count(args.attachment_files)      
        attachment_ok_count = 0
        
        log_file, log_file_count = create_log_file()
        append_log(f"File {log_file} successfully generated")
        append_log(f"{log_file_count} totals file log")
        
        append_log(f"{attachment_count} totals attachment") 
        
        email_config = read_config_data()
        append_log("Switching for the right provider")
        provider = ""
        if "smtp" in email_config and email_config["smtp"] and not email_config.get("oauth"):
            provider = "smtp"
            append_log("** SMTP Version **")    
        elif "oauth" in email_config and email_config["oauth"]:
            provider = "gmail"
            append_log("** Gmail OAuth version **")         
        elif not email_config["smtp"] and email_config["fromemail"] and not email_config.get("oauth"):     
            provider = "smtp"
            append_log("** SMTP Version - without login **")         
        else:
            process_output(True, "Can't switch provider", 1)
            
        attachment_ok_count = send_email(args.subject, args.to_address, args.mail_body_html, args.attachment_files, email_config, provider, args.mail_bulk)
        
        if attachment_ok_count is None:
            attachment_ok_count = 0
        
        final_output_message = "<< Email Sent >>"
        
        if attachment_ok_count < attachment_count:
            final_output_message = final_output_message + "\n>> Soft warning: something wrong with 1 or more attachments, check logs for more info >>"

        final_output_message = final_output_message + is_secure_directory()
            
        process_output(False, f"{final_output_message}", 0)
        
    except Exception as e:
        process_output(True, f"Error: {e}", 1)

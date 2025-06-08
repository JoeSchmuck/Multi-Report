#!/usr/bin/env python3

import smtplib, json, argparse, os, stat, time, base64, subprocess, socket, uuid, requests, sys
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from email.utils import formatdate, parseaddr
from email import message_from_string
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials

##### V 1.11
##### Stand alone script to send email via Truenas

def validate_arguments(args):
    """
        new function for an easier validation of the args passed to the function, due the fact there are now 2 calls methods. If mail_body_html is passed, nor subject and to_address are mandatory
    """
    if not args.mail_bulk and not args.mail_body_html:
        print("Error: You must provide at least --mail_bulk or --mail_body_html.")
        sys.exit(1)
    if args.mail_body_html and (not args.subject or not args.to_address):
        print("Error: If --mail_body_html is provided, both --subject and --to_address are required.")
        sys.exit(1)
    if args.debug_enabled:
        if not os.access(os.getcwd(), os.W_OK):
            print(f"Current user doesn't have permission in the execution folder: {os.getcwd()}")
            sys.exit(1)     
        sfw = is_secure_directory()
        if sfw:
            print(f"{sfw}")
        
def is_secure_directory(directory_to_check=None):
    """
        this function help to report eventually security concerns about the usage context of the script. Promemorial: The function itself not log anything, output should be used when logfile available
    """
    if not args.debug_enabled:    
        return ""
    else:    
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
            sys.exit(1)          

def create_log_file():
    """
        We setup a folder called sendemail_log where store log's file on every start if --debug_enabled is set. Every Logfiles can be safely deleted.
    """   
    
    if not args.debug_enabled:    
        return None, 0
    else:
        try:    
            log_dir = os.path.join(os.getcwd(), 'sendemail_log')
            
            if os.path.islink(log_dir):
                print("Something wrong is happening here: the sendemail_log folder is a symlink")
                sys.exit(1)  
            
            if not os.path.exists(log_dir):
                os.makedirs(log_dir)
                log_file_count = 0  
            else:                 
                log_files = [f for f in os.listdir(log_dir) if f.endswith('.txt') and os.path.isfile(os.path.join(log_dir, f)) and not os.path.islink(os.path.join(log_dir, f))]
                log_file_count = len( log_files )  
            log_file_count = log_file_count + 1   

            timestamp = time.strftime("%Y%m%d_%H%M%S", time.localtime())
            log_file_path = os.path.join(log_dir, f"{timestamp}.txt")

            if not os.path.exists(log_file_path):
                with open(log_file_path, 'w') as f:
                    pass              
            return log_file_path, log_file_count
        except Exception as e:
            print(f"Something wrong managing logs: {e}")
            sys.exit(1)          

def append_log(content):
    """
        Centralized file log append
    """   
    if args.debug_enabled:        
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
    response = json.dumps({"error": error, "detail": detail, "logfile": log_file, "total_attach": attachment_count, "ok_attach": attachment_count_valid}, ensure_ascii=False)
    append_log(f"{detail}") 
    print(response)
    if exit_code is not None:
        sys.exit(exit_code)

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
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_file = os.path.join(script_dir, "multi_report_config.txt")

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
        append_log(f"Error reading {config_file}: {e}")
        return ""

    return ""

def get_outlook_access_token():
    """get an access token using the tn refresh token in truenas"""
    
    append_log("retrieving access token") 
    oauth_url = "https://login.microsoftonline.com/common/oauth2/v2.0/token"    
    data = {
        "client_id": email_config["oauth"]["client_id"],
        "client_secret": email_config["oauth"]["client_secret"],
        "refresh_token": email_config["oauth"]["refresh_token"],
        "grant_type": "refresh_token",
        "scope": "https://outlook.office.com/SMTP.Send openid offline_access"
    }   
    try:
        response = requests.post(oauth_url, data=data)   
        if response.status_code == 200:
            append_log("got access token!") 
            return response.json()["access_token"]
        else:
            process_output(True, f"response for the access token has an error: {response.text}", 1)   
    except Exception as e:
        process_output(True, f"A problem occurred retrieving access token: {e}", 1)
        
def get_fromname_fromemail(options):
    """ centralized function to retrieve from name - from email """
    try:
        for fromname, fromemail, log_message in options:
            if fromemail:
                append_log(log_message)
                return f"{fromname} <{fromemail}>" if fromname else fromemail, fromemail
        return None, None
    except Exception as e:
        process_output(True, f"A problem occurred retrieving data: {e}", 1)
            
def send_email(subject, to_address, mail_body_html, attachment_files, email_config, provider, bulk_email):
    """
    Function to send an email via SMTP or Gmail OAuth based on the provider available
    """
    attachment_ok_count = 0 
    tn_fromemail = email_config["fromemail"]
    tn_fromname = email_config["fromname"]    
    fallback_fromname = getMRconfigvalue("FromName")
    fallback_fromemail = getMRconfigvalue("From")     
    override_fromname = args.override_fromname
    override_fromemail = args.override_fromemail    
    from_options = [
        (override_fromname, override_fromemail, "using override fromname-email"),
        (fallback_fromname, fallback_fromemail, "using mr-config fromname-email"),
        (tn_fromname, tn_fromemail, "using default fromname-email"),
        (override_fromname, tn_fromemail, "using override fromname with tn email"),
        (fallback_fromname, tn_fromemail, "using fallback fromname with tn email"),
        (None, override_fromemail, "using override fromemail"),
        (None, fallback_fromemail, "using mr-config fromemail"),
        (None, tn_fromemail, "using default fromemail")
    ]       
    
    if provider == "smtp":
        try:
            append_log("parsing smtp config") 
            smtp_security = email_config["security"]
            smtp_server = email_config["outgoingserver"]
            smtp_port = email_config["port"]
            smtp_user = email_config["user"]
            smtp_password = email_config["pass"]
            smtp_login = email_config["smtp"]
 
            append_log("switch from classic send and bulk email")    
            if mail_body_html:
                append_log("mail hmtl provided")
                append_log("parsing html content") 
                html_content = load_html_content(mail_body_html)

                append_log("start parsing headers")
                msg = MIMEMultipart()
                
                append_log("parsing data from config and override options")                                 
                msg['From'], smtp_senderemail = get_fromname_fromemail(from_options)                                              
                msg['To'] = to_address
                msg['Subject'] = subject
                msg.attach(MIMEText(html_content, 'html'))
                
                append_log(f"generate a message ID using {smtp_user}")
                try:
                    messageid_domain = smtp_user.split("@")[1]
                except Exception:
                    append_log(f"{smtp_user} not a valid address, tryng on {smtp_senderemail}")
                    try:
                        messageid_domain = smtp_senderemail.split("@")[1]
                    except Exception:
                        append_log(f"{smtp_senderemail} not a valid address, need to use a fallback ")
                        messageid_domain = "local.me"
                append_log(f"domain: {messageid_domain}")
                messageid_uuid = f"{datetime.now().strftime('%Y_%m_%d_%H_%M_%S_%f')[:-3]}{uuid.uuid4()}"
                append_log(f"uuid: {messageid_uuid}")
                messageid = f"<{messageid_uuid}@{messageid_domain}>"
                append_log(f"messageid: {messageid}")
                msg['Message-ID'] = messageid
                msg['Date'] = formatdate(localtime=True)                
                
                append_log("check for attachements...") 
                if attachment_files:
                    append_log("attachments found") 
                    attachment_ok_count = attach_files(msg, attachment_files, attachment_ok_count)
                    append_log(f"{attachment_ok_count} ok attachments") 
                    
                append_log("get hostname")     
                try:
                    hostname = socket.getfqdn()
                    if not hostname:
                        hostname = socket.gethostname()  
                except Exception:
                    process_output(True, "A problem occurred retrieving hostname", 1)     
                append_log(f"hostname retrieved: {hostname}")   
                
                append_log("tryng retrieving if more recipient are set")
                try:    
                    to_address = [email.strip() for email in to_address.split(",")] if "," in to_address else to_address.strip()
                except Exception as e:
                    process_output(True, f"Error parsing recipient: {e}", 1)                 
            
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
                    from_address = mime_msg['From']
                    try:
                        _, smtp_senderemail = parseaddr(from_address)
                        append_log("sender retrieved")
                    except Exception as e:
                        process_output(True, f"Error parsing sender: {e}", 1)  
                    if to_address:
                        append_log("recipient retrieved")
                        try:    
                            to_address = [email.strip() for email in to_address.split(",")] if "," in to_address else to_address.strip()
                        except Exception as e:
                            process_output(True, f"Error parsing recipient: {e}", 1)                         
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
                    append_log(f"sending {smtp_security} email") 
                    server.sendmail(smtp_senderemail, to_address, msg.as_string())
            elif smtp_security == "SSL":
                with smtplib.SMTP_SSL(smtp_server, smtp_port) as server:
                    append_log(f"entered {smtp_security} path")   
                    if hostname:        
                        append_log("adding ehlo to the message")          
                        server.ehlo(hostname)   
                    if smtp_login:           
                        append_log("entering credentials") 
                        server.login(smtp_user, smtp_password)
                    append_log(f"sending {smtp_security} email") 
                    server.sendmail(smtp_senderemail, to_address, msg.as_string())
            elif smtp_security == "PLAIN":
                with smtplib.SMTP(smtp_server, smtp_port) as server:
                    append_log(f"entered {smtp_security} path")   
                    if hostname:        
                        append_log("adding ehlo to the message")          
                        server.ehlo(hostname)  
                    if smtp_login:    
                        append_log("entering credentials")
                        server.login(smtp_user, smtp_password)   
                    append_log(f"sending {smtp_security} email") 
                    server.sendmail(smtp_senderemail, to_address, msg.as_string())        
            else:
                process_output(True, "KO: something wrong switching SMTP security level", 1)             

            append_log("Email Sent via SMTP")
            return attachment_ok_count            

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
                
                append_log("parsing data from config and override options")                                 
                msg['From'], smtp_senderemail = get_fromname_fromemail(from_options)                                         
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
            
    elif provider == "outlook":
        try:
            new_access_token = get_outlook_access_token()
            append_log("parsing smtp config for outlook") 
            smtp_security = email_config["security"]
            smtp_server = email_config["outgoingserver"]
            smtp_port = email_config["port"]
                  
            append_log("switch from classic send and bulk email")   
            if mail_body_html:
                append_log("mail hmtl provided")
                append_log("parsing html content") 
                html_content = load_html_content(mail_body_html)

                append_log("start parsing headers")
                msg = MIMEMultipart()
                append_log("parsing data from config and override options")                                 
                msg['From'], smtp_senderemail = get_fromname_fromemail(from_options) 
                msg['To'] = to_address
                msg['Subject'] = subject
                msg.attach(MIMEText(html_content, 'html'))
                
                append_log(f"generate a message ID using {smtp_senderemail}")
                try:
                    messageid_domain = smtp_senderemail.split("@")[1]
                except Exception:
                    append_log(f"{smtp_senderemail} not a valid address, need to use a fallback ")
                    messageid_domain = "local.me"
                    
                append_log(f"domain: {messageid_domain}")
                messageid_uuid = f"{datetime.now().strftime('%Y_%m_%d_%H_%M_%S_%f')[:-3]}{uuid.uuid4()}"
                append_log(f"uuid: {messageid_uuid}")
                messageid = f"<{messageid_uuid}@{messageid_domain}>"
                append_log(f"messageid: {messageid}")
                msg['Message-ID'] = messageid
                msg['Date'] = formatdate(localtime=True)                
                
                append_log("check for attachements...") 
                if attachment_files:
                    append_log("attachments found") 
                    attachment_ok_count = attach_files(msg, attachment_files, attachment_ok_count)
                    append_log(f"{attachment_ok_count} ok attachments") 
                    
                append_log("get hostname")     
                try:
                    hostname = socket.getfqdn()
                    if not hostname:
                        hostname = socket.gethostname()  
                except Exception:
                    process_output(True, "A problem occurred retrieving hostname", 1)     
                append_log(f"hostname retrieved: {hostname}")   
                
                append_log("tryng retrieving if more recipient are set")
                try:    
                    to_address = [email.strip() for email in to_address.split(",")] if "," in to_address else to_address.strip()
                except Exception as e:
                    process_output(True, f"Error parsing recipient: {e}", 1)        
                            
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
                    from_address = mime_msg['From']
                    try:
                        _, smtp_senderemail = parseaddr(from_address)
                        append_log("sender retrieved")
                    except Exception as e:
                        process_output(True, f"Error parsing sender: {e}", 1)                      
                    if to_address:
                        append_log("recipient retrieved")
                        try:    
                            to_address = [email.strip() for email in to_address.split(",")] if "," in to_address else to_address.strip()
                        except Exception as e:
                            process_output(True, f"Error parsing recipient: {e}", 1)                         
                        msg = mime_msg
                    else:
                        process_output(True, "failed retriving recipient", 1)    
                except Exception as e:
                    process_output(True, f"Error decoding Base64 content: {e}", 1)                
                 
            else:
                process_output(True, "Something wrong with the data input", 1)  

            append_log("establing connection") 
            if smtp_security == "TLS":
                with smtplib.SMTP(smtp_server, smtp_port) as server:
                    append_log(f"confirmed {smtp_security} path")                                 
                    append_log("establing TLS connection")    
                    server.starttls()
                    if hostname:        
                        append_log("adding ehlo to the message")          
                        server.ehlo(hostname)     
                    else:
                        append_log("invoking ehlo")
                        server.ehlo()                  
                    append_log("starting auth with access token")
                    auth_string = f"user={tn_fromemail}\1auth=Bearer {new_access_token}\1\1"
                    server.docmd("AUTH XOAUTH2 " + base64.b64encode(auth_string.encode()).decode())                                                        
                    append_log(f"sending {smtp_security} email") 
                    server.sendmail(smtp_senderemail, to_address, msg.as_string())
                    
                    append_log("Email Sent via Outlook")
                    return attachment_ok_count  
            else:
                process_output(True, "Something wrong... TLS not set in TN?", 1)   
        except Exception as e:    
            process_output(True, f"KO: {e}", 1)
        
    else:
        process_output(True, "No valid email configuration found.", 1)
                                
  
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Workaround to send email easily in Multi Report using Truenas mail.config")
    parser.add_argument("--subject", help="Email subject. Mandatory when using -mail_body_html")
    parser.add_argument("--to_address", help="Recipient email address. Mandatory when using -mail_body_html")
    parser.add_argument("--mail_body_html", help="File path for the email body, or just a plain text/html. No encoding needed")
    parser.add_argument("--attachment_files", help="OPTIONAL attachments as json file path array. No ecoding needed", nargs='*')
    parser.add_argument("--mail_bulk", help="Bulk email with all necessary parts, encoded and combined together. File path or plain text supported. Content must be served as Base64 without newline /n, the recipient will be get from the To in the message")
    parser.add_argument("--debug_enabled", help="OPTIONAL use to let the script debug all steps into log files. Usefull for troubleshooting", action='store_true')
    parser.add_argument("--override_fromname", help="OPTIONAL override sender name from TN config")
    parser.add_argument("--override_fromemail", help="OPTIONAL override sender email from TN config")    
    
    args = parser.parse_args()
    
    validate_arguments(args) 

    try:        
        log_file, log_file_count = create_log_file()
        append_log(f"File {log_file} successfully generated")
        append_log(f"{log_file_count} totals file log")
        
        attachment_count = calc_attachment_count(args.attachment_files)  
        attachment_count_valid = 0      
        append_log(f"{attachment_count} totals attachment to handle") 
        
        email_config = read_config_data()
        append_log("Switching for the right provider")             
        provider = ""        
        tn_provider = tn_provider = email_config.get("oauth", {}).get("provider", "gmail")
        
        if "smtp" in email_config and email_config["smtp"] and not email_config.get("oauth"):
            provider = "smtp"
            append_log("** SMTP Version **")  
        elif not email_config["smtp"] and not email_config.get("oauth"):     
            provider = "smtp"
            append_log("** SMTP Version - without login **")               
        elif "oauth" in email_config and email_config["oauth"] and tn_provider == "gmail":
            provider = "gmail"
            append_log("** Gmail OAuth version **")        
        elif "oauth" in email_config and email_config["oauth"] and tn_provider == "outlook":
            provider = "outlook"
            append_log("** Outlook OAuth version **")                     
        else:
            process_output(True, "Can't switch provider", 1)
            
        attachment_count_valid = send_email(args.subject, args.to_address, args.mail_body_html, args.attachment_files, email_config, provider, args.mail_bulk)
        
        if attachment_count_valid is None:
            attachment_count_valid = 0
        
        final_output_message = "<< Email Sent >>"
        
        if attachment_count_valid < attachment_count:
            final_output_message = final_output_message + "\n>> Soft warning: something wrong with 1 or more attachments >>"

        final_output_message = final_output_message + is_secure_directory()
            
        process_output(False, f"{final_output_message}", 0)
        
    except Exception as e:
        process_output(True, f"Error: {e}", 1)

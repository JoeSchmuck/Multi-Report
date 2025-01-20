#!/usr/bin/env python3

import smtplib, json, argparse, os, time, base64, subprocess, socket, uuid
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from email.utils import formatdate
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials

##### V 0.09
##### Stand alone script to send email via Truenas

def validate_arguments(args):
    """
        new function for an easier validation of the args passed to the function, due the fact there are now 2 calls methods
    """
    if not args.mail_bulk and not args.mail_body_html:
        print("Error: You must provide at least --mail_bulk or --mail_body_html.")
        exit(1)
    if args.mail_body_html:
        if not args.subject or not args.to_address:
            print("Error: If --mail_body_html is provided, both --subject and --to_address are required.")
            exit(1)

def create_log_file():
    """
        We setup a folder called sendemail_log where store log's file on every start. Oldest mrlog folder can be safely deleted
    """       
    log_dir = os.path.join(os.getcwd(), 'sendemail_log')
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
        log_file_count = 0
    else:    
        log_files = [f for f in os.listdir(log_dir) if f.endswith('.txt') and os.path.isfile(os.path.join(log_dir, f))]
        log_file_count = len( log_files )
        if log_file_count >= 15: #wanna delete oldest log file to not let them increase overall
            oldest_file = min(log_files, key=lambda f: os.path.getctime(os.path.join(log_dir, f)))   
            os.remove(os.path.join(log_dir, oldest_file))         

    timestamp = time.strftime("%Y%m%d_%H%M%S", time.localtime())
    log_file_path = os.path.join(log_dir, f"{timestamp}.txt")

    if not os.path.exists(log_file_path):
        with open(log_file_path, 'w') as f:
            pass 

    return log_file_path, log_file_count

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
    print(response) # caller must intercept this if wanna do something with the result of this process
    if exit_code is not None:
        exit(exit_code)

def read_config_data():
    """
     function for read the mail.config from midclt 
    """    
    append_log(f"trying read mail.config") 
    midclt_output = subprocess.run(
        ["midclt", "call", "mail.config"],
        capture_output=True,
        text=True
    )
    if midclt_output.returncode != 0:
        process_output(True, f"Failed to call midclt: {midclt_output.stderr.strip()}", 1)
        
    append_log(f"read mail.config successfully")                
    midclt_config = json.loads(midclt_output.stdout)
    return midclt_config

def load_html_content(input_content):
    """
     use this fuction to switch from achieve nor a file to read and a plain text/html
    """
    try:        
        if len(input_content) > 255:
            append_log(f"body can't be a file, too much long")
            return input_content
        elif os.path.exists(input_content):
            with open(input_content, 'r') as f:
                append_log(f"body is a file") 
                return f.read()
        else:
            append_log(f"no file found, plain text/html output") 
            return input_content            
    except Exception as e:
        process_output(True, f"Something wrong on body content {e}", 1)  

def validate_base64_content(input_content):
    """
    use this funtcion to validate that an input is base64encoded. Return error if not
    """      
    try:
        base64.b64decode(input_content, validate=True) 
        append_log(f"Base64 message is valid.")
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
    config_file = "multi_report_config.txt" #default
    
    if not os.path.exists(config_file):
        append_log(f"{config_file} not found")
        return ""

    try:
        with open(config_file, "r") as file:
            for line in file:
                line = line.strip()
                key_value_pair, _, comment = line.partition('#') # necessary to not get dirty values
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
    if provider == "smtp":  #smtp version
        try:
            append_log(f"parsing smtp config") 
            smtp_security = email_config["security"]
            smtp_server = email_config["outgoingserver"]
            smtp_port = email_config["port"]
            smtp_user = email_config["user"]
            smtp_password = email_config["pass"]
            smtp_fromemail = email_config['fromemail']
            smtp_fromname = email_config['fromname']
            
            append_log(f"switch from classic send and bulk email")    
            if mail_body_html:
                append_log(f"mail hmtl provided")
                append_log(f"parsing html content") 
                html_content = load_html_content(mail_body_html)

                append_log(f"start parsing headers")
                msg = MIMEMultipart()
                append_log(f"parsing data from config") 
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
                except:
                    append_log(f"{smtp_user} not a valid address, tryng on {smtp_fromemail}")
                    try:
                        messageid_domain = smtp_fromemail.split("@")[1]
                    except:
                        append_log(f"{smtp_fromemail} not a valid address, need to use a fallback ")
                        messageid_domain = "local.me"
                append_log(f"domain: {messageid_domain}")
                messageid_uuid = f"{datetime.now().strftime('%Y_%m_%d_%H_%M_%S_%f')[:-3]}{uuid.uuid4()}"
                append_log(f"uuid: {messageid_uuid}")
                messageid = f"<{messageid_uuid}@{messageid_domain}>"
                append_log(f"messageid: {messageid}")
                msg['Message-ID'] = messageid
                msg['Date'] = formatdate(localtime=True) #
                
                
                append_log(f"check for attachements...") 
                if attachment_files:
                    append_log(f"attachments found") 
                    attachment_ok_count = attach_files(msg, attachment_files, attachment_ok_count)
                    append_log(f"{attachment_ok_count} ok attachments") 
                    
                append_log(f"get hostname")     
                hostname = socket.getfqdn()
                if not hostname:
                    hostname = socket.gethostname()  
                append_log(f"hostname retrieved: {hostname}")   
            
            elif bulk_email:
                append_log(f"using bulk email provided")
                msg = load_html_content(bulk_email)
                validate_base64_content(msg)  
            else:
                process_output(True, f"Something wrong with the data input", 1)

            append_log(f"establing connection based on security level set on TN: {smtp_security}") 
            if smtp_security == "TLS":
                with smtplib.SMTP(smtp_server, smtp_port) as server:
                    append_log(f"entered {smtp_security} path")   
                    #server.set_debuglevel(1)  #### this line can be uncommented if more debug is needed 
                    append_log(f"adding ehlo to the message")                   
                    server.ehlo(hostname)      
                    append_log(f"establing TLS connection")    
                    server.starttls()
                    append_log(f"entering credentials") 
                    server.login(smtp_user, smtp_password)
                    append_log(f"sending {smtp_security} email") 
                    server.sendmail(smtp_user, to_address, msg.as_string())
            elif smtp_security == "SSL":
                with smtplib.SMTP_SSL(smtp_server, smtp_port) as server:
                    append_log(f"entered {smtp_security} path")   
                    #server.set_debuglevel(1)  #### this line can be uncommented if more debug is needed    
                    append_log(f"adding ehlo to the message")                
                    server.ehlo(hostname)         
                    append_log(f"entering credentials") 
                    server.login(smtp_user, smtp_password)
                    append_log(f"sending {smtp_security} email") 
                    server.sendmail(smtp_user, to_address, msg.as_string())
            elif smtp_security == "PLAIN":
                with smtplib.SMTP(smtp_server, smtp_port) as server:
                    append_log(f"entered {smtp_security} path")   
                    #server.set_debuglevel(1)  #### this line can be uncommented if more debug is needed    
                    append_log(f"adding ehlo to the message")  
                    server.ehlo(hostname)
                    append_log(f"entering credentials")
                    server.login(smtp_user, smtp_password)
                    append_log(f"sending {smtp_security} email") 
                    server.sendmail(smtp_user, to_address, msg.as_string())        
            else:
                process_output(True, f"KO: something wrong switching SMTP security level", 1)             

            append_log(f"Email Sent via SMTP")

        except Exception as e:
            process_output(True, f"KO: {e}", 1)

    elif provider == "gmail":  # gmail version
        try:
            append_log(f"parsing Oauth config") 
            credentials = Credentials.from_authorized_user_info(email_config["oauth"])
            service = build('gmail', 'v1', credentials=credentials)
            
            append_log(f"switch from classic send and bulk email")     
            if mail_body_html:                  
                append_log(f"mail hmtl provided")
                append_log(f"start parsing headers")          
                msg = MIMEMultipart()
                append_log(f"parsing data from config") 
                fallback_fromname = getMRconfigvalue("FromName") # we need a FromName setting into mr config
                fallback_fromemail = getMRconfigvalue("From")
                
                if fallback_fromname and fallback_fromemail:
                    msg['From'] = f"{fallback_fromname} <{fallback_fromemail}>"
                    append_log(f"using fallback fromname") 
                elif fallback_fromemail: 
                    msg['From'] = fallback_fromemail
                    append_log(f"using fallback fromemail")         
                else:
                    append_log(f"can't find a from setting. Gmail will apply the default")  
                    
                msg['to'] = to_address
                msg['subject'] = subject
                        
                append_log(f"parsing html content") 
                html_content = load_html_content(mail_body_html)            
                msg.attach(MIMEText(html_content, 'html'))
                
                append_log(f"check for attachements...") 
                if attachment_files:
                    append_log(f"attachments found") 
                    attachment_ok_count = attach_files(msg, attachment_files, attachment_ok_count)
                    append_log(f"{attachment_ok_count} ok attachments")   
                      
                append_log(f"Encoding message")     
                raw_message = msg.as_bytes() 
                msg = base64.urlsafe_b64encode(raw_message).decode('utf-8')                
                    
            elif bulk_email:
                append_log(f"using bulk email provided")
                msg = load_html_content(bulk_email)
                validate_base64_content(msg)          
            else:
                process_output(True, f"Something wrong with the data input", 1)                                                     
            
            append_log(f"sending email")           
            message = service.users().messages().send(userId="me", body={'raw': msg}).execute()
            
            append_log(f"Email Sent via Gmail")
            return attachment_ok_count

        except Exception as e:
            process_output(True, f"KO: {e}", 1)

    else:
        process_output(True, "No valid email configuration found.", 1)
                                
  
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Workaround to send email easily in Multi Report")
    parser.add_argument("--subject", help="Email subject")
    parser.add_argument("--to_address", help="Recipient")
    parser.add_argument("--mail_body_html", help="File path for the email body, or just a plain text/html")
    parser.add_argument("--attachment_files", nargs='*', help="OPTIONAL attachments as json file path array. No ecoding needed")
    parser.add_argument("--mail_bulk", help="Bulk email with all necessary parts, encoded and combined. File path or plain text supported")

    args = parser.parse_args()
    
    validate_arguments(args) 

    try:
        attachment_count = calc_attachment_count(args.attachment_files)      
        attachment_ok_count = 0 #avoid error if except are raised
        
        log_file, log_file_count = create_log_file()
        append_log(f"File {log_file} successfully generated")
        append_log(f"{log_file_count} totals file log")
        
        append_log(f"{attachment_count} totals attachment") 
        
        email_config = read_config_data()
        append_log(f"Switching for the right provider")
        provider = ""
        if "smtp" in email_config and email_config["smtp"] and not email_config.get("oauth"):
            provider = "smtp"
            append_log(f"** SMTP Version **")    
        elif "oauth" in email_config and email_config["oauth"]:
            provider = "gmail"
            append_log(f"** Gmail OAuth version **")                     
        else:
            process_output(True, f"Can't switch provider", 1)
            
        attachment_ok_count = send_email(args.subject, args.to_address, args.mail_body_html, args.attachment_files, email_config, provider, args.mail_bulk)
        
        if attachment_ok_count is None:
            attachment_ok_count = 0
        
        if attachment_ok_count == attachment_count:
            process_output(False, f">> All is Good <<", 0)
        else:
            process_output(False, f">> Soft warning: something wrong with 1 or more attachments, check logs for more info >>", 0)
    except Exception as e:
        process_output(True, f"Error: {e}", 1)

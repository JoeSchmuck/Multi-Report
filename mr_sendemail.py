import smtplib, json, argparse, os, time, base64, subprocess
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials

def create_log_file():
    """
        We setup a folder called mrlog where store log's file on every start
    """       
    log_dir = os.path.join(os.getcwd(), 'mrlog')
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

def load_html_content(mail_body_html):
    """
     let user to pass nor a file to read and a plain text/html
    """
    try:
        with open(mail_body_html, 'r') as f:
            append_log(f"body is a file") 
            return f.read()
    except FileNotFoundError:
        append_log(f"no file found, plain text/html output") 
        return mail_body_html
    except Exception as e:
        process_output(True, f"Something wrong on body content {e}", 1)  
        
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
            
def send_email(subject, to_address, mail_body_html, attachment_files, email_config, provider):
    """
    Function to send an email via SMTP or Gmail OAuth based on the provider available
    """
    attachment_ok_count = 0  
    if provider == "smtp":  #smtp version
        try:
            append_log(f"parsing smtp config") 
            smtp_server = email_config["outgoingserver"]
            smtp_port = email_config["port"]
            smtp_user = email_config["user"]
            smtp_password = email_config["pass"]

            append_log(f"parsing html content") 
            html_content = load_html_content(mail_body_html)

            msg = MIMEMultipart()
            msg['From'] = smtp_user
            msg['To'] = to_address
            msg['Subject'] = subject
            msg.attach(MIMEText(html_content, 'html'))

            append_log(f"check for attachements...") 
            if attachment_files:
                append_log(f"attachments found") 
                attachment_ok_count = attach_files(msg, attachment_files, attachment_ok_count)
                append_log(f"{attachment_ok_count} ok attachments") 

            append_log(f"establing connection...") 
            with smtplib.SMTP(smtp_server, smtp_port) as server:
                server.starttls()
                server.login(smtp_user, smtp_password)
                server.sendmail(smtp_user, to_address, msg.as_string())

            append_log(f"Email Sent via SMTP")

        except Exception as e:
            process_output(True, f"KO: {e}", 1)

    elif provider == "gmail":  # gmail version
        try:
            append_log(f"parsing Oauth config") 
            credentials = Credentials.from_authorized_user_info(email_config["oauth"])
            service = build('gmail', 'v1', credentials=credentials)
            
            append_log(f"parsing data from config") 
            msg = MIMEMultipart()
            msg['From'] = f"{email_config['fromemail'] if email_config['fromemail'] else to_address} <{email_config['fromname']}>"
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
    parser.add_argument("--subject", required=True, help="Email subject")
    parser.add_argument("--to_address", required=True, help="Recipient")
    parser.add_argument("--mail_body_html", required=True, help="File path for the email body, or just a plain text/html")
    parser.add_argument("--attachment_files", nargs='*', help="OPTIONAL attachments as json file path array")

    args = parser.parse_args()

    try:
        attachment_count = calc_attachment_count(args.attachment_files)      
        attachment_ok_count = 0
        
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
            
        attachment_ok_count = send_email(args.subject, args.to_address, args.mail_body_html, args.attachment_files, email_config, provider)
        
        if attachment_ok_count == attachment_count:
            process_output(False, f">> All is Good <<", 0)
        else:
            process_output(False, f">> Soft warning: something wrong with 1 or more attachments >>", 0)
    except Exception as e:
        process_output(True, f"Error: {e}", 1)
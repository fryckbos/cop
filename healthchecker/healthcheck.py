import os
import sys
import time
import requests
import threading
import logging
import smtplib
from email.mime.text import MIMEText
from concurrent.futures import ThreadPoolExecutor, as_completed

logging.basicConfig(format='%(asctime)s [%(levelname)s] %(message)s', level=logging.INFO)

class EmailAlerter:

    def __init__(self, mail_server, mail_port, mail_ssl, mail_auth, mail_username, mail_password, from_email, to_email):
        self.mail_server = mail_server
        self.mail_port = mail_port
        self.mail_ssl = mail_ssl
        self.mail_auth = mail_auth
        self.mail_username = mail_username
        self.mail_password = mail_password
        self.from_email = from_email
        self.to_email = to_email

    def test(self, subject, message):
        threading.Thread(target=self.send_mail, args=('test', subject, message)).start()

    def triggered(self, subject, message):
        threading.Thread(target=self.send_mail, args=('trigger', subject, message)).start()

    def resolved(self, subject, message):
        threading.Thread(target=self.send_mail, args=('resolve', subject, message)).start()

    def send_mail(self, purpose, subject, message):
        logging.info("Sending %s email '%s'", purpose, subject)
        try:
            msg = MIMEText(message)
            msg['From'] = self.from_email
            msg['To'] = self.to_email
            msg['Subject'] = subject
             
            server = smtplib.SMTP(self.mail_server, self.mail_port)
            if self.mail_ssl:
                server.starttls()
            if self.mail_auth:
                server.login(self.mail_username, self.mail_password)

            server.sendmail(self.from_email, self.to_email, msg.as_string())
            server.quit()

            logging.info("Done sending %s email '%s'", purpose, subject)
        except Exception as e:
            logging.error("Failed to send %s email '%s': %s", purpose, subject, e)


class HttpCheck:

    def __init__(self, name, method, url, data=None):
        self.name = name

        self.method = method
        if method not in ['GET', 'POST']:
            raise Exception('method is not GET or POST')

        self.url = url
        self.data = data

    def get_name(self):
        return self.name

    def check(self):
        logging.info("Starting check '%s'", self.name)
        start = time.time()

        try:
            if self.method == 'GET':
                r = requests.get(self.url, timeout = 60)
            elif self.method == 'POST':
                r = requests.post(self.url, data = self.data, timeout = 60)

            if r.status_code != 200:
                raise Exception('Incorrect status code: %d' % r.status_code)

        except Exception as e:
            ms = int((time.time() - start) * 1000)
            logging.warn("Check '%s' failed (took %d ms): %s", self.name, ms, e)
            return (False, str(e))
        else:
            ms = int((time.time() - start) * 1000)
            logging.info("Check '%s' succeeded (took %d ms)" , self.name, ms)
            return (True, None)


class Checker:

    def __init__(self, alerter, check_period):
        self.alerter = alerter
        self.check_period = check_period
        self.checks = []
        self.failing_checks = {}

    def add_check(self, check):
        self.checks.append(check)

    def run(self):
        while True:
            logging.info('Starting check iteration.')
            failed_checks = self.check()
            (triggered, resolved) = self.update_failing_checks(failed_checks)

            if len(self.failing_checks) == 0:
                all_failing = "All health checks pass."
            else:
                all_failing = "All failing health checks:\n\n    " + "\n\n    ".join(check.get_name() for check in self.failing_checks)

            if len(triggered) > 0:
                msg = "New health check failures:\n\n    " + "\n\n    ".join(triggered) + "\n\n\n" + all_failing
                self.alerter.triggered("[TRIGGERED] CoScale monitoring health check", msg)

            if len(resolved) > 0:
                msg = "Resolved health checks:\n\n    " + "\n\n    ".join(resolved) + "\n\n\n" + all_failing
                self.alerter.resolved("[RESOLVED] CoScale monitoring health check", msg)

            logging.info('Check iteration done, sleeping %d seconds', check_period)
            time.sleep(check_period)

    def check(self):
        failed_checks = {}

        with ThreadPoolExecutor(max_workers = len(self.checks)) as executor:
            future_to_checks = {executor.submit(check.check): check for check in self.checks}
            
            for future in as_completed(future_to_checks):
                check = future_to_checks[future]
                try:
                    (success, msg) = future.result()
                except Exception as e:
                    failed_checks[check] = "Exception during check: %s" % e
                else:
                    if not success:
                        failed_checks[check] = msg

        return failed_checks

    def update_failing_checks(self, failed_checks):
        (triggered, resolved) = ([], [])

        for check in failed_checks:
            if check not in self.failing_checks:
                self.failing_checks[check] = True
                triggered.append("%s : %s" % (check.get_name(), failed_checks[check]))

        for check in list(self.failing_checks):
            if check not in failed_checks:
                self.failing_checks.pop(check)
                resolved.append("%s : back to normal" % check.get_name())

        return (triggered, resolved)



def get_env_var(variable, convert=None):
    ''' Get an environment variable. Checks whether it is present and not empty, exitst with return
    code 1 on error. '''
    value = os.environ.get(variable)

    if value is None:
        print("Environment variable %s is not present." % variable)
        sys.exit(1)
    elif len(value) == 0:
        print("Environment variable %s is empty." % variable)
        sys.exit(1)

    if convert is None:
        return value
    elif convert == 'int':
        try:
            return int(value)
        except Exception as e:
            print("Environment variable %s (%s) is not an integer." % (variable, value))
            sys.exit(1)
    elif convert == 'bool':
        return value.lower() == "true"
    else:
        raise Exception('Only int and bool are accepted for convert.')


if __name__ == '__main__':
    mail_server = get_env_var('MAIL_SERVER')
    mail_port = get_env_var('MAIL_PORT', 'int')
    mail_ssl = get_env_var('MAIL_SSL', 'bool')
    mail_auth = get_env_var('MAIL_AUTH', 'bool')
    mail_username = get_env_var('MAIL_USERNAME') if mail_auth else None
    mail_password = get_env_var('MAIL_PASSWORD') if mail_auth else None
    from_email = get_env_var('FROM_EMAIL')
    support_email = get_env_var('SUPPORT_EMAIL')

    api_user = get_env_var('API_SUPER_USER')
    api_passwd = get_env_var('API_SUPER_PASSWD')
    api_url = get_env_var('API_URL')
    app_url = get_env_var('APP_URL')
    rum_url = get_env_var('RUM_URL')

    check_period = get_env_var('CHECK_PERIOD', 'int')
    test = get_env_var('TEST_HEALTH_ALERT', 'bool')

    alerter = EmailAlerter(mail_server, mail_port, mail_ssl, mail_auth, mail_username, mail_password, from_email, support_email)
    if test:
        alerter.test("CoScale HealthCheck Alert Test",
                     "This is a test email from the CoScale HealthCheck.\n\n"
                     "This email was sent while starting the HealthChecker because the TEST_HEALTH_ALERT environment variable was present.")

    checker = Checker(alerter, check_period)
    checker.add_check(HttpCheck('Api login', 'POST', '%s/api/v1/users/login/' % api_url, {'email' : api_user, 'password' : api_passwd}))
    checker.add_check(HttpCheck('Api datastore health', 'POST', '%s/api/v1/app/00076273-bd30-4916-9594-9b6c23758fc6/data/healthCheck/' % api_url))
    checker.add_check(HttpCheck('Api event health', 'GET', '%s/api/v1/app/00076273-bd30-4916-9594-9b6c23758fc6/events/healthCheck/' % api_url))
    checker.add_check(HttpCheck('App login page', 'GET', '%s/' % app_url))
    checker.add_check(HttpCheck('Rum snippet', 'GET', 'http://%s/rum/v1/js/coscale-rum.js' % rum_url))
    checker.run()

#########################
#region install packages to import selenium
##########################
import subprocess

# Define the package name you want to install
package_name1 = 'selenium'
package_name2 = 'selenium_stealth'

#package1
try:
    # Use subprocess to run the 'pip install' command
    subprocess.check_call(['pip', 'install', package_name1])

    # Print a message indicating successful installation
    print(f'Successfully installed {package_name1}')

except subprocess.CalledProcessError as e:
    # Handle any installation errors
    print(f'Error: Failed to install {package_name1}. Details: {e}')

except Exception as e:
    # Handle other exceptions
    print(f'An error occurred: {e}')

#package2
try:
    # Use subprocess to run the 'pip install' command
    subprocess.check_call(['pip', 'install', package_name2])

    # Print a message indicating successful installation
    print(f'Successfully installed {package_name2}')

except subprocess.CalledProcessError as e:
    # Handle any installation errors
    print(f'Error: Failed to install {package_name2}. Details: {e}')

except Exception as e:
    # Handle other exceptions
    print(f'An error occurred: {e}')

#########################
#endregion
#########################

##
# Disable Chrome updates after its installed
# https://www.chromium.org/administrators/turning-off-auto-updates/
##

from selenium import webdriver
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.chrome.service import Service
from selenium_stealth import stealth
from datetime import datetime, timedelta
import time
import shutil

path_to_values = 'C:\\Users\\Matt\\Documents\\values.txt'

# Get the current date
current_date = datetime.now()
# Calculate yesterday's date
yesterday_raw = current_date - timedelta(days=1)
# different formats for the dates
today_formatted = current_date.strftime("%Y-%m-%d")
yesterday_formatted = yesterday_raw.strftime("%m-%d-%Y")
yesterday_formatted2 = yesterday_raw.strftime("%Y-%m-%d")

#########################
#region read in values
#########################
variables = {}  # Dictionary to store the variables and their values

# Read the 'values.txt' file
with open(path_to_values, 'r') as file:
    for line in file:
        line = line.strip()
        if line:
            var_name, var_value = line.split(' = ')
            variables[var_name] = var_value

# Now you can access the variables as needed
bnloginurl = variables['bnloginurl']
bnusername = variables['bn_username']
bnpassword = variables['bn_password']
chromedriver_path = variables['chromedriver_path']
chomedownload_path = variables['chromedownload_path']
path_to_reports = variables['path_to_reports']

#########################
#endregion
#########################

#########################
#region Download report
#########################

#setup chrome driver as service
chrome_service = Service(chromedriver_path)

#setup options to stealth it up
options = webdriver.ChromeOptions()
options.add_argument("start-maximized")
# options.add_argument("--headless")
options.add_experimental_option("excludeSwitches", ["enable-automation"])
options.add_experimental_option('useAutomationExtension', False)

#pass options to chrome driver
driver = webdriver.Chrome(options=options, service=chrome_service)
stealth(driver,
        languages=["en-US", "en"],
        vendor="Google Inc.",
        platform="Win32",
        webgl_vendor="Intel Inc.",
        renderer="Intel Iris OpenGL Engine",
        fix_hairline=True,
        )

#a url to test stealth effectiveness with
#url = "https://bot.sannysoft.com/"

#open URL
driver.get(bnloginurl)
time.sleep(3)

#pop in login info
email_element = driver.find_element("id", "signin_email")
email_element.send_keys(bnusername)
time.sleep(1)
password_input = driver.find_element("id", "signin_password")
password_input.send_keys(bnpassword)
time.sleep(2)

# Click the "Sign In" button
sign_in_button = driver.find_element("xpath", "//button[contains(text(),'Sign In')]")
sign_in_button.click()
time.sleep(30)

# After the login, perform a click anywhere on the screen to deal with MFA pop up
action_chains = ActionChains(driver)
action_chains.move_by_offset(100, 100)  # Adjust the offset based on your needs
action_chains.click().perform()

#salespage = "https://press.barnesandnoble.com/sales"   #WORKS!
#THIS ALSO WORKS
#reportwewant = "https://press.barnesandnoble.com/sales/reports?reportType=recentSales&sort=saleDate&descending=true&f_fromDate=07-27-2023&f_toDate=07-27-2023&f_groupByTitle=false"
urlpart1 = "https://press.barnesandnoble.com/sales/reports?reportType=recentSales&sort=saleDate&descending=true&f_fromDate="
urlpart2 = yesterday_formatted
urlpart3 = "&f_toDate="
urlpart4 = yesterday_formatted
urlpart5 = "&f_groupByTitle=false"
reportwewant = urlpart1 + urlpart2 + urlpart3 + urlpart4 + urlpart5

#now load that page since the url itself does much of the hard work for us
driver.get(reportwewant)
time.sleep(15)

#now click the download button
export_link = driver.find_element("xpath", '//a[contains(@href, "/api/salesreporting/export?reportType=recentSales")]')
export_link.click()

time.sleep(20)
driver.quit()
#########################
#endregion
#########################

#########################
#region rename & move to reports dir
#########################
#example source C:\Users\Matt\Downloads\recent_sales_2023-07-28.csv
#example dest "C:\AutomatedReportDownloader\reports\BN-07-28-2023.csv"

sourcefilepart1 = 'recent_sales_'
sourcefilepart2 = today_formatted       #even tho we asked for yesterdays report - the date is today
sourcefilepart3 = '.csv'
fullsource = chomedownload_path + sourcefilepart1 + sourcefilepart2 + sourcefilepart3

destfilepart1 = 'BN-'
destfilepart2 = yesterday_formatted
destfilepart3 = '.csv'
fulldestination = path_to_reports + destfilepart1 + destfilepart2 + destfilepart3

# Use shutil.move() to move the file
shutil.move(fullsource, fulldestination)
#########################
#endregion
#########################
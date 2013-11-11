# gdoc_puller.rb

For when you need to pull down a google spreadsheet into CSV over and over again.

# Usage

1. Add a document

    gdoc_puller.rb adddocs

  This asks you to login to your google doc account, and will show you a list of spreadsheets.  Select the sheet that you want to pull down.  By default it will only store your username and the document name.  Pass in "--savepass" if you want to save the password.  Be advised, this is saved in plaintext in the currect directory in the file "gdoc_info.yml" and should not be checked into git.

2. Pull the documents

    gdoc_puller.rb pulldocs

  This pulls down each sheet of each doc into your ~/Downloads directory.


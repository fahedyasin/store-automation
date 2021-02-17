# store-automation

Prerequisites:
- Github CLI
    brew install gh
    gh auth login
- RubyGems
- XCodeProj
- Nokogiri

Run command for index.sh:
index.sh "Fahed Store 42" 8 5 https://demo.storespal.com "StoresPal" 1024.png https://storespal.com/privacypolicy https://storespal.com/ fahed@saee.sa

Run command for distributing app via Testflight
distribute.sh "Fahed Store 42" https://storespal.com/privacypolicy https://storespal.com/ fahed@saee.sa

Run command for Ruby script: 
ios_target_generator.rb STORE_NAME STORE_ID WEBSITE_ID BASE_URL COMPANY_NAME APP_ICON_1024_FILE

EXAMPLE: 
ios_target_generator.rb "Fahed Store 41" 8 5 https://demo.storespal.com "StoresPal" 1024.png


AppIcon Generator: ios_icon_generator.sh 1024.png output/

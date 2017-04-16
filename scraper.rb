require 'HTTParty'
require 'Nokogiri'
require 'JSON'
require 'Pry'
require 'csv'

monstersHtml = HTTParty.get('http://www.orcpub.com/dungeons-and-dragons/5th-edition/monsters')
monsters = Nokogiri::HTML(monstersHtml)

xPathSelector = '//*[@id="app"]/div/div[3]/div/div/div/div/a'
elems = monsters.xpath(xPathSelector)

# child pages
children = []

CSV.open('monster-pages.csv', 'w') do |csv|
    elems.each do |e|
        # puts "#{e}\n\n"

        childName = e['href'].split('/').last
        childLink = "http://www.orcpub.com" + e['href']

        # print and save
        puts "#{childName}\t#{childLink}\n"
        csv << [childName, childLink]
        children.push([childName, childLink])
    end
end

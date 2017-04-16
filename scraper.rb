require 'HTTParty'
require 'Nokogiri'
require 'JSON'
require 'Pry'
require 'csv'

def monsterPages()
    monstersHtml = HTTParty.get('http://www.orcpub.com/dungeons-and-dragons/5th-edition/monsters')
    monsters = Nokogiri::HTML(monstersHtml)

    elems = monsters.xpath('//*[@id="app"]/div/div[3]/div/div/div/div/a')

    # child pages
    pages = []

    CSV.open('monster-pages.csv', 'w') do |csv|
        elems.each do |e|
            # puts "#{e}\n\n"

            childName = e['href'].split('/').last
            childLink = "http://www.orcpub.com" + e['href']

            # print and save
            puts "#{childName}\t#{childLink}\n"
            csv << [childName, childLink]
            pages.push([childName, childLink])
        end
    end

    return pages
end

def textBlockHash(monster, titleXPath, descriptionXPath)
    titles = monster.xpath(titleXPath).map { |e| e.text }
    descriptions = monster.xpath(descriptionXPath).map { |e| e.text }
    data = Hash[[titles, descriptions].transpose]
    data.default = ""
    return data
end

def textBlock(monster, titleXPath, descriptionXPath)
    titles = monster.xpath(titleXPath).map { |e| e.text }
    descriptions = monster.xpath(descriptionXPath).map { |e| e.text }
    return titles.zip(descriptions).join(" ")
end

def monsterPage(url)
    data = Hash.new("")
    monsterHtml = HTTParty.get(url)
    monster = Nokogiri::HTML(monsterHtml).xpath('//*[@id="app"]/div/div[3]')

    data['title'] = monster.xpath('//h1/span').text

    info = monster.xpath('//*[@id="app"]/div/div[3]/div/div/div/div[1]')

    data['size'] = info.xpath('//div[1]/em[1]').text
    data['type'] = info.xpath('//div[1]/em[2]').text
    data['alignment'] = info.xpath('//div[1]/em[4]').text
    data['ac'] = info.xpath('//div[2]/div[1]/span').text
    data['speed'] = info.xpath('//div[2]/div[3]/span').text

    data['hp_avg'] = info.xpath('//div[2]/div[2]/span/span/span[1]').text
    data['hp_dice'] = info.xpath('//div[2]/div[2]/span').text.split(/[()]/)[1].delete(' ')

    stats = info.xpath('//div[3]/table/tbody/tr')
    data['str'] = stats.xpath('//td[1]/div').text
    data['dex'] = stats.xpath('//td[2]/div').text
    data['con'] = stats.xpath('//td[3]/div').text
    data['int'] = stats.xpath('//td[4]/div').text
    data['wis'] = stats.xpath('//td[5]/div').text
    data['cha'] = stats.xpath('//td[6]/div').text

    detailTitleXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[1]/div[4]/div/h5'
    detailDescriptionXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[1]/div[4]/div/span'
    details = textBlockHash(monster, detailTitleXPath, detailDescriptionXPath)
    data['proficiency'] = details['Proficiency Bonus']
    data['saving_throws'] = details['Saving Throws']
    data['skills'] = details['Skills']
    data['senses'] = details['Senses']
    data['languages'] = details['Languages']
    data['cr'] = details['Challenge'].split(/[() ]/)[0]
    data['xp'] = details['Challenge'].split(/[() ]/)[1]

    # TODO figure out how to split up special, actions, and legendary actions
    # eg. to support looking for a specific action
    specialTitleXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[1]/div[5]/p/em/strong'
    specialDescriptionXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[1]/div[5]/p/span'
    data['special'] = textBlock(monster, specialTitleXPath, specialDescriptionXPath)

    actionsTitleXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[2]/p/em/strong'
    actionsDescriptionXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[2]/p/span'
    data['actions'] = textBlock(monster, actionsTitleXPath, actionsDescriptionXPath)

    data['legendaryActionsText'] = monster.xpath('//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[3]/p[1]').text
    legendaryActionsTitleXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[3]/p/em/strong'
    legendaryActionsDescriptionXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[3]/p/span'
    data['legendaryActions'] = textBlock(monster, legendaryActionsTitleXPath, legendaryActionsDescriptionXPath)

    puts data

end

monsterPage('http://www.orcpub.com/dungeons-and-dragons/5th-edition/monsters/hobgoblin')

monsterPage('http://www.orcpub.com/dungeons-and-dragons/5th-edition/monsters/aboleth')

# monsterPage('http://www.orcpub.com/dungeons-and-dragons/5th-edition/monsters/gnome--deep-svirfneblin')
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

def textBlock(monster, titleXPath, descriptionXPath)
    titles = monster.xpath(titleXPath).map { |e| e.text }
    descriptions =  monster.xpath(descriptionXPath).map { |e| e.text }
    return titles.zip(descriptions).join(" ")
end

def monsterPage(url)
    monsterHtml = HTTParty.get(url)
    monster = Nokogiri::HTML(monsterHtml).xpath('//*[@id="app"]/div/div[3]')

    title = monster.xpath('//h1/span').text
    puts "title: #{title}"

    info = monster.xpath('//*[@id="app"]/div/div[3]/div/div/div/div[1]')

    size = info.xpath('//div[1]/em[1]').text
    type = info.xpath('//div[1]/em[2]').text
    alignment = info.xpath('//div[1]/em[4]').text
    ac = info.xpath('//div[2]/div[1]/span').text
    speed = info.xpath('//div[2]/div[3]/span').text
    puts "size: #{size} type: #{type} alignment: #{alignment} ac: #{ac} speed: #{speed}"

    hp_avg = info.xpath('//div[2]/div[2]/span/span/span[1]').text
    hp_dice = info.xpath('//div[2]/div[2]/span').text.split(/[()]/)[1].delete(' ')
    puts "hp_avg: #{hp_avg} hp_dice: #{hp_dice}"

    stats = info.xpath('//div[3]/table/tbody/tr')
    str = stats.xpath('//td[1]/div').text
    dex = stats.xpath('//td[2]/div').text
    con = stats.xpath('//td[3]/div').text
    int = stats.xpath('//td[4]/div').text
    wis = stats.xpath('//td[5]/div').text
    cha = stats.xpath('//td[6]/div').text
    puts "str: #{str} dex: #{dex} con: #{con} int: #{int} wis: #{wis} cha: #{cha}"

    proficiency = info.xpath('//div[4]/div[1]/span').text
    saving_throws = info.xpath('//div[4]/div[2]/span').text
    skills = info.xpath('//div[4]/div[3]/span').text
    senses = info.xpath('//div[4]/div[4]/span').text
    languages = info.xpath('//div[4]/div[5]/span').text
    puts "proficiency: #{proficiency} saving_throws: #{saving_throws} skills: #{skills} senses: #{senses} languages: #{languages}"

# '//*[@id="app"]/div/div[3]/div/div/div/div[1]/div[4]/div[5]/span/span/span[1]'
# CR is getting messed up b/c some monsters dont have saving throws
    cr = info.xpath('//div[4]/div[6]/span/span/span[1]').text
    xp = info.xpath('//div[4]/div[6]/span/span/span[3]').text
    puts "cr: #{cr} xp: #{xp}"

    specialTitleXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[1]/div[5]/p/em/strong'
    specialDescriptionXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[1]/div[5]/p/span'
    special = textBlock(monster, specialTitleXPath, specialDescriptionXPath)
    puts "special: #{special}"

    actionsTitleXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[2]/p/em/strong'
    actionsDescriptionXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[2]/p/span'
    actions = textBlock(monster, actionsTitleXPath, actionsDescriptionXPath)
    puts "actions: #{actions}"

    legendaryActionsText = monster.xpath('//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[3]/p[1]').text
    legendaryActionsTitleXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[3]/p/em/strong'
    legendaryActionsDescriptionXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[3]/p/span'
    legendaryActions = textBlock(monster, legendaryActionsTitleXPath, legendaryActionsDescriptionXPath)
    puts "legendaryActionsText: #{legendaryActionsText} legendaryActions: #{legendaryActions}"

end

monsterPage('http://www.orcpub.com/dungeons-and-dragons/5th-edition/monsters/hobgoblin')

# monsterPage('http://www.orcpub.com/dungeons-and-dragons/5th-edition/monsters/aboleth')

# monsterPage('http://www.orcpub.com/dungeons-and-dragons/5th-edition/monsters/gnome--deep-svirfneblin')
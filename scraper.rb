require 'HTTParty'
require 'Nokogiri'
require 'JSON'
require 'Pry'
require 'csv'

def monsterPages(save=false, verbose=false)
    monstersHtml = HTTParty.get('http://www.orcpub.com/dungeons-and-dragons/5th-edition/monsters')
    monsters = Nokogiri::HTML(monstersHtml)

    elems = monsters.xpath('//*[@id="app"]/div/div[3]/div/div/div/div/a')

    # child pages
    pages = []

    CSV.open('monster-pages.csv', 'w') do |csv|
        elems.each do |e|
            childName = e['href'].split('/').last
            childLink = "http://www.orcpub.com" + e['href']

            # print and save
            if verbose
                puts "#{childName}\t#{childLink}\n"
            end
            if save
                csv << [childName, childLink]
            end
            pages.push(childLink)
        end
    end

    return pages
end

def spellPages(save=false, verbose=false)
    spellsHtml = HTTParty.get('http://www.orcpub.com/dungeons-and-dragons/5th-edition/spells')
    spells = Nokogiri::HTML(spellsHtml)
    elems = spells.xpath('//*[@id="app"]/div/div[3]/div/div[1]/div/div/a')

    # child pages
    pages = []

    CSV.open('spell-pages.csv', 'w') do |csv|
        elems.each do |e|
            childName = e['href'].split('/').last
            childLink = "http://www.orcpub.com" + e['href']

            # print and save
            if verbose
                puts "#{childName}\t#{childLink}\n"
            end
            if save
                csv << [childName, childLink]
            end
            pages.push(childLink)
        end
    end

    return pages
end

def textBlockHash(root, titleXPath, descriptionXPath)
    titles = root.xpath(titleXPath).map { |e| e.text }
    descriptions = root.xpath(descriptionXPath).map { |e| e.text }
    data = Hash[[titles, descriptions].transpose]
    data.default = ''
    return data
end

def textBlock(root, titleXPath, descriptionXPath)
    titles = root.xpath(titleXPath).map { |e| e.text }
    descriptions = root.xpath(descriptionXPath).map { |e| e.text }
    return titles.zip(descriptions).join(' ')
end

def monsterPage(url, verbose=false)
    data = Hash.new('')
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
    data['str'] = stats.xpath('//td[1]/div').text.split(/[() ]/)[0]
    data['str_mod'] = stats.xpath('//td[1]/div').text.split(/[() ]/)[2]
    data['dex'] = stats.xpath('//td[2]/div').text.split(/[() ]/)[0]
    data['dex_mod'] = stats.xpath('//td[2]/div').text.split(/[() ]/)[2]
    data['con'] = stats.xpath('//td[3]/div').text.split(/[() ]/)[0]
    data['con_mod'] = stats.xpath('//td[3]/div').text.split(/[() ]/)[2]
    data['int'] = stats.xpath('//td[4]/div').text.split(/[() ]/)[0]
    data['int_mod'] = stats.xpath('//td[4]/div').text.split(/[() ]/)[2]
    data['wis'] = stats.xpath('//td[5]/div').text.split(/[() ]/)[0]
    data['wis_mod'] = stats.xpath('//td[5]/div').text.split(/[() ]/)[2]
    data['cha'] = stats.xpath('//td[6]/div').text.split(/[() ]/)[0]
    data['cha_mod'] = stats.xpath('//td[6]/div').text.split(/[() ]/)[2]

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
    data['special'] = textBlock(monster, specialTitleXPath, specialDescriptionXPath).gsub(/[\r\n]/,'')

    actionsTitleXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[2]/p/em/strong'
    actionsDescriptionXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[2]/p/span'
    data['actions'] = textBlock(monster, actionsTitleXPath, actionsDescriptionXPath).gsub(/[\r\n]/,'')

    data['legendary_actions_text'] = monster.xpath('//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[3]/p[1]').text.gsub(/[\r\n]/,'')
    legendaryActionsTitleXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[3]/p/em/strong'
    legendaryActionsDescriptionXPath = '//*[@id="app"]/div/div[3]/div/div/div/div[3]/div/div[3]/p/span'
    data['legendary_actions'] = textBlock(monster, legendaryActionsTitleXPath, legendaryActionsDescriptionXPath).gsub(/[\r\n]/,'')

    if verbose
        puts data
    end

    return data
end

def spellPage(url, verbose=false)
    data = Hash.new('')
    spellHtml = HTTParty.get(url)
    spell = Nokogiri::HTML(spellHtml).xpath('//*[@id="app"]/div/div[3]')

    data['title'] = spell.xpath('//h1//span').text

    level_type = spell.xpath('//div/em').text.split(' ')
    if level_type[1] == 'cantrip'
        data['level'] = 0
        data['type'] = level_type[0]
    else
        data['level'] = level_type[0].match(/(\d+)/)[1]
        data['type'] = level_type[1]
    end

    data['time'] = spell.xpath('//div/div[1]/div/div/div[2]/span').text
    data['range'] = spell.xpath('//div/div[1]/div/div/div[3]/span').text
    data['components'] = spell.xpath('//div/div[1]/div/div/div[4]/span').text
    data['duration'] = spell.xpath('//div/div[1]/div/div/div[5]/span').text

    data['description'] = spell.xpath('//div/div[1]/div/div/div[6]').text.gsub(/[\r\n]/,'')

    if verbose
        puts data
    end

    return data
end

def scrapeMonsters(save=false, verbose=false)
    pages = monsterPages(save, verbose)

    if verbose
        puts "\n\n"
    end

    CSV.open('monsters.csv', 'w') do |csv|
        pages.each_with_index do |page, index|

            # rate limiting
            sleep(1)

            if verbose
                puts "\n\n"
            end
            puts "#{index+1}/#{pages.length}"

            m = monsterPage(page, verbose)

            if save
                csv << [m['title'], m['size'], m['type'], m['alignment'], m['ac'], m['speed'], m['hp_avg'], m['hp_dice'], m['str'], m['str_mod'], m['dex'], m['dex_mod'], m['con'], m['con_mod'], m['int'], m['int_mod'], m['wis'], m['wis_mod'], m['cha'], m['cha_mod'], m['proficiency'], m['saving_throws'], m['skills'], m['senses'], m['languages'], m['cr'], m['xp'], m['special'], m['actions'], m['legendary_actions_text'], m['legendary_actions']]
            end
        end
    end
end

# scrapeMonsters(true, true)

def scrapeSpells(save=false, verbose=false)
    pages = spellPages(save, verbose)

    if verbose
        puts "\n\n"
    end

    CSV.open('spells.csv', 'w') do |csv|
        pages.each_with_index do |page, index|

            # rate limiting
            sleep(1)

            if verbose
                puts "\n\n"
            end
            puts "#{index+1}/#{pages.length}"

            s = spellPage(page, verbose)

            if save
                csv << [s['title'], s['level'], s['type'], s['time'], s['range'], s['components'], s['duration'], s['description']]
            end
        end
    end
end

# scrapeSpells(true, true)

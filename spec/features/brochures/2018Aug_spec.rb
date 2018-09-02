#p "Here: #{File.realpath(__FILE__)}, #{__FILE__}, #{__dir__}"
#p "target: #{File.expand_path('../../..', __FILE__)}"

require File.expand_path('../../../rails_helper', __FILE__)
# require 'rails_helper'

describe "2018 Aug Brochure" do
  sbf_link = 'http://esales.hdb.gov.sg/hdbvsf/eampu08p.nsf/0/18AUGROF_page_9046/$file/about0.html'
  # sbf_link = 'file://localhost/Users/prusswan/Downloads/sobf.html'
  details_dropdown = "//div[@id='MenuBoxTop']//a[contains(@class,'t7')]"
  price_dropdown = "//div[@id='MenuBoxTop']//a[contains(@class,'t8')]"

  block_fields = [:probable_date, :delivery_date, :lease_start, :estate_id, :no, :street]
  unit_fields = [:price, :area, :flat_type]

  def find_block_info(item)
    text = item.split[0]
    # page.find(:xpath, "//td[@class='textLabelNew' and contains(.,'#{text}')]/following-sibling::td[1]").text
    page.find(:xpath, "//div[@id='blockDetails']//div[b[contains(.,'#{text}')]]/following-sibling::div[1]").text
  end

  quota_fields = ['malay','chinese','others','flat_type','block_id']

  def parse_quota(quota_str)
    r = quota_str.match /(\d+)\D+(\d+)\D+(\d+)/
    r[1..3].map(&:to_i)
  end

  def title_font_color
    # '#855553' # TODO: can we search for this next time?
    '#90191C'
  end

  def check_search_window(estate_name)
    return true if windows.length < 2

    # switch_to_window(windows.last)

    within_window(->{ page.title.starts_with? 'Flats Available' }) do
      # p page.body
      p "multiple windows: flat summary"
      selected_town = first(:xpath, "//select[@name='Town']")
      p "selected_town: #{selected_town.value}"
      return selected_town.nil? || selected_town.value.gsub(' /','/') != estate_name
    end
  end

  before do
    # current_window.resize_to(1200, 800)

    visit sbf_link
    sleep 1
  end

  it "parsing unit counts (new layout - main page)" do
    # dropdown_link = find_link('Price Range')
    # dropdown_link = find(:xpath, "//li[contains(@class,'has-dropdown')]/a[text()='Price Range']")
    dropdown_link = find(:xpath, "//li[contains(@class,'has-dropdown')][a[text()='Price Range']]")
    # dropdown_link2 = find(:xpath, "//li[contains(@class,'parent-link')][a[text()='Price Range']]", visible: false)
    dropdown = find(:xpath, "//ul[preceding-sibling::a[contains(@class, 'secondLine') and text()='Price Range']]")

    # estates = page.all(:xpath, "//ul[preceding-sibling::a[contains(@class, 'secondLine') and text()='Price Range']]//a[contains(@href,'html')]").map(&:text)
    estates = page.all(:xpath, "//tbody/tr[1]/td[1][count(following-sibling::td)=7]").map(&:text).each_with_index.to_a.sort_by {|p| p.first }

    puts estates.count
    # puts estates

    # page.execute_script("document.getElementsByClassName('large-11')[0].remove()");
    # page.execute_script("document.getElementsByClassName('footer')[0].remove()");

    total = 0

    estates.each do |e|
      estate_name, position = e
      estate_name = estate_name.gsub(' / ', '/ ') # sanitizing... don't ask

      estate = Estate.find_or_initialize_by(name: estate_name)
      next unless estate.new_record?

      # while all(:xpath, "//h1[contains(normalize-space(text()), '#{page_title}')]").count == 0 do
      #   # dropdown_link.trigger(:mouseover)
      #   # dropdown_link.trigger(:click)
      #   dropdown_link.click # does not work on webkit
      #   # save_and_open_screenshot

      #   within(dropdown) do
      #     # link = find_link(estate_name)
      #     link = find(:xpath, "//a[text()='#{estate_name}' and contains(@href,'price')]")
      #     # p link
      #     # link.trigger(:mouseover)
      #     # link.trigger(:click)

      #     link.click
      #   end
      # end

      # supply = page.all(:xpath, "//div[contains(@class, 'table-container')]//td[2]").map(&:text).map(&:to_i).inject(:+)
      # supply = page.all(:xpath, "//div[contains(@class, 'table-container')]//td[2][preceding-sibling::td[not(contains(.,'remaining'))]]")
      #              .map{ |t| t.text.gsub(',','').gsub('*','').to_i }.inject(:+)
      # supply = page.all(:xpath, "//td[contains(string(.//strong),'#{estate_name}')]/following-sibling::td[2]").map(&:text).map(&:to_i).inject(:+)

      # puts "looking for: #{estate_name} #{position}"
      position += 1 # to avoid matching the header row

      # check the position by counting sibling elements
      rows = page.all(:xpath, "//tbody[count(preceding-sibling::tbody[tr[1]/td[1]])=#{position}][tr[1]/td]/tr[position() != 1]/td[2][count(following-sibling::td)=5]")
                 .map(&:text).map(&:to_i)
      first_row = find(:xpath, "//tbody[count(preceding-sibling::tbody[tr[1]/td[1]])=#{position}][tr[1]/td]/tr[1]/td[3][count(following-sibling::td)=5]").text.to_i

      rows << first_row
      supply = rows.inject(:+)

      total += supply

      puts "#{estate_name}: #{supply} / #{total}"

      # estate = Estate.find_or_initialize_by(name: estate_name)
      # puts "!!! mismatch: #{estate.total} != #{rows}" if estate.total != supply
      estate.update(total: supply) if supply > 0 && estate.total != supply
    end
  end

  it "parsing unit details" do
    main_window = windows.first

    Estate.all.each do |estate|
      puts "Estate: #{estate.name}"

      next if estate.units.count == estate.total
      # next unless estate.name.starts_with? 'Pasir'
      # next unless ['Bukit Panjang', 'Choa Chu Kang', 'Hougang', 'Jurong East',
      #   'Jurong West', 'Punggol', 'Sembawang', 'Sengkang', 'Woodlands', 'Yishun']
      #   .include?(estate.name)

      # close extra flat summary tabs
      while windows.length > 1 do
        windows.last.close
      end

      while check_search_window(estate.name) do
        within_window(main_window) do
          # dropdown_link = find_link('Flat Details')
          dropdown_link = find(:xpath, "//li[contains(@class,'has-dropdown')][a[text()='Flat Details']]")
          # dropdown_link.trigger(:mouseover)
          dropdown_link.hover

          dropdown = find(:xpath, "//ul[preceding-sibling::a[text()='Flat Details']]")
          within(dropdown) do
            link = find_link(estate.name)
            p link['onclick']

            # link['onclick'].should == "goFlats('../../13MAYSBF_page_5789/$file/map.htm?open&ft=sbf&twn=GL')"
            # link.click
            page.execute_script(link['onclick'])
            sleep 5
          end
        end

        # p windows

        windows.each do |w|
          within_window(w) do
            puts page.title
          end
        end
      end

      within_window(->{ page.title.starts_with? 'Flats Available' }) do
        flat_types = page.all(:xpath, "//select[@name='Flat']/option")
        # flat_types.count.should == 5

        flat_types.map(&:text).each do |flat_type|
          # next unless flat_type.starts_with? '5'

          puts "Type: #{flat_type}"
          select flat_type, from: 'Flat'

          within('div#flatDetails') do
            click_button 'Search'
          end

          sleep 5

          within('div#blockDetails') do
            # block_nos = page.all(:xpath, "//strong[contains(.,'Click on block no')]/ancestor::tr[1]/following-sibling::tr//a")
            loop do
              # block_divs = page.all(:xpath, "//strong[contains(.,'Click on block no')]/ancestor::tr[1]/following-sibling::tr//a/div")
              block_fonts = page.all(:xpath, "//table[contains(.,'Click on block no')]//td//font[descendant::a]")
              block_divs = page.all(:xpath, "//table[contains(.,'Click on block no')]//td/div[font/a]")

              while all(:xpath, "//span[@role='tooltip']").count == 0 do
                sleep 1
              end
              street_tooltips = page.all(:xpath, "//span[@role='tooltip']")
              streets = Hash[street_tooltips.map {|s| [ s[:'data-selector'], s[:title] ]}]

              @block_links = block_fonts.each_with_index.map do |b, i|
                # id = b[:id]
                # no = page.find(:xpath, "//div[@id='#{id}']/ancestor::a[1]")
                # street = page.find(:xpath, "//div[@id='#{id}']//font").text

                no = b.text
                # street = b[:title].strip
                street = streets[ b['data-selector'] ]
                link = block_divs[i][:onclick]

                # [no.text(:visible), street, no[:href]]
                tuple = [no, street, link]
                p tuple
                tuple
              end

              break if @block_links.count > 0
            end

            puts "Blocks: #{@block_links.count}"

            @block_links.each do |no, street, link|
              # puts street, link.last
              puts no, street, link

              # expected_state = %Q{
              #   //strong[contains(.,'Click on block no')]/ancestor::tr[1]/following-sibling::tr
              #   //b[contains(.,'#{link.first}')]
              #   //font[contains(.,\"#{link[1]}\")]
              # }
              expected_state = %Q{
                //div[@id='blockDetails']//div[contains(text(),'#{no}')][following-sibling::div[contains(.,\"#{street.upcase}\")]]
              }

              # click on block no to display block info

              loop do
                begin
                  while all(:xpath, expected_state).count == 0
                    page.execute_script(link)
                    sleep 2
                  end
                rescue Exception => error
                  # p error
                end
                break if error.nil?
              end

              block_info = ['Probable Completion Date', 'Delivery Possession Date',
                'Lease Commencement Date'].map do |item|
                # puts "#{item}: #{find_block_info(item)}"
                find_block_info(item)
              end << estate.id << no << street

              quota_str = find_block_info('Available Ethnic Quota')

              block_hash = Hash[block_fields.zip(block_info)]

              block = Block.where(no: no, street: street).first_or_create(block_hash)
              block.update_attribute(:link, link)

              quota_info = parse_quota(quota_str) << flat_type << block.id
              quota_hash = Hash[quota_fields.zip(quota_info)]
              quota = Quota.where(flat_type: flat_type, block_id: block.id).first_or_create(quota_hash)
              # quota.update_attributes(quota_hash) # to update existing quotas containing wrong values
              p quota.inspect

              # unit_nos = page.all(:xpath, "//td[contains(.,'Mouseover unit number')]/ancestor::table[1]/following-sibling::table//font")
              unit_nos = page.all(:xpath, "//table[thead//th[contains(text(),'Mouseover\u00a0unit\u00a0number')]]//font/a/font", visible: true)
              puts "Units: #{unit_nos.count}"

              unit_nos.map(&:text).each do |no|
                # get price and area
                # selector = "//font[contains(.,'#{no}')]/ancestor::td[1]/div[1]//td"
                # selector = "//font[contains(.,'#{no}')][a]"
                selector = "//span[@id='#{no}k']"
                unit_str = page.find(:xpath, selector)

                fields = unit_str[:title].split(/<br(?:\/)?>/)
                area = fields[-1].to_i
                price = fields[-3].gsub(/[$,]/,'').to_i # max price

                # unit_info = page.all(:xpath, selector)
                #                 .map(&:text).map{|v| v.gsub(/\D/,'').to_i} << flat_type << quota.id
                unit_info = [price, area] << flat_type << quota.id
                p [no] + unit_info

                unit_hash = Hash[unit_fields.zip(unit_info)].merge!({quota_id: quota.id})
                if fields.length > 3
                  unit_hash[:price_str] = fields[0..-3].join("\n")
                  p unit_hash[:price_str]
                end

                unit = Unit.where(no: no, block: block).first_or_create(unit_hash)
              end

              sleep (unit_nos.count/10 + 1)
            end

            sleep (@block_links.count/10 + 1)
          end
        end
      end
    end
  end

  pending 'parsing unit counts' do
    # pending 'already parsed flat supply numbers'
    estates = page.all(:xpath, "//div[@id='cssdrivemenu2']//a").map(&:text)

    puts estates.count
    # puts estates.map(&:text)
    estates.each do |estate|
      while all(:xpath, "//font[@color='#{title_font_color}' and contains(normalize-space(text()), '#{estate}')]").count == 0 do
        within('div#cssdrivemenu2') do
          while true
            dropdown = page.all(:xpath, price_dropdown)

            if dropdown.count > 0
              dropdown.first.trigger(:mouseover)
              break
            end
          end

          link = find_link(estate)
          link.click
        end
      end

      supply = page.all(:xpath, "//tr[@bgcolor='#FFFFFF']/td[2]").map(&:text).map(&:to_i).inject(:+)
      puts "#{estate}: #{supply}"

      Estate.where(name: estate, total: supply).first_or_create
    end
  end
end

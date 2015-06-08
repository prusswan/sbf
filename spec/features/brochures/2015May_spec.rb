require 'spec_helper'

describe "2015 May Brochure" do
  sbf_link = 'http://esales.hdb.gov.sg/hdbvsf/eampu05p.nsf/0/15MAYSBF_page_1905/$file/about0.html'
  # sbf_link = 'file://localhost/Users/prusswan/Downloads/sobf.html'
  details_dropdown = "//div[@id='MenuBoxTop']//a[contains(@class,'t7')]"
  price_dropdown = "//div[@id='MenuBoxTop']//a[contains(@class,'t8')]"

  block_fields = [:no, :street, :probable_date, :delivery_date, :lease_start, :estate_id]
  unit_fields = [:price, :area, :flat_type]

  def find_block_info(item)
    text = item.split[0]
    page.find(:xpath, "//td[@class='textLabelNew' and contains(.,'#{text}')]/following-sibling::td[1]").text
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

  before do
    page.driver.allow_url("services2.hdb.gov.sg")
    page.driver.allow_url("esales.hdb.gov.sg")
    page.driver.allow_url("www.google-analytics.com")
    page.driver.allow_url("fonts.googleapis.com")

    visit sbf_link
    sleep 1
  end

  it "new page layout" do
    dropdown_link = find_link('Flat Details')
    dropdown_link.trigger(:mouseover)

    dropdown = find(:xpath, "//ul[preceding-sibling::a[text()='Flat Details']]")
    within(dropdown) do
      link = find_link('Bukit Merah')
      p link['onclick']

      # link.click
      page.execute_script(link['onclick'])
    end

    handles = windows # page.driver.window_handles
    p handles
    p page.title

    within_window(->{ page.title == 'Flat Search' }) do
      p page.title
    end
  end

  it "parsing unit counts (new layout)" do
    dropdown_link = find_link('Price Range')
    dropdown = find(:xpath, "//ul[preceding-sibling::a[text()='Price Range']]")

    estates = page.all(:xpath, "//ul[preceding-sibling::a[text()='Price Range']]//a").map(&:text)
    puts estates.count
    # puts estates

    estates.each do |estate_name|
      page_title = estate_name.gsub('/', ' ').gsub('Sengkang','SengKang') # sanitizing... don't ask

      while all(:xpath, "//h1[contains(normalize-space(text()), '- #{page_title}')]").count == 0 do
        dropdown_link.trigger(:mouseover)

        within(dropdown) do
          link = find_link(estate_name)
          # link.trigger(:mouseover)
          link.trigger(:click)
        end
      end

      supply = page.all(:xpath, "//div[@class='table-container']//td[2]").map(&:text).map(&:to_i).inject(:+)
      puts "#{estate_name}: #{supply}"

      estate = Estate.where(name: estate_name, total: supply).first_or_create
    end
  end

  pending "load details page" do
    Estate.all.each do |estate|
      puts "Estate: #{estate.name}"

      next if estate.units.count == estate.total
      # next unless estate.name.starts_with? 'Pasir'
      # next unless ['Bukit Panjang', 'Choa Chu Kang', 'Hougang', 'Jurong East',
      #   'Jurong West', 'Punggol', 'Sembawang', 'Sengkang', 'Woodlands', 'Yishun']
      #   .include?(estate.name)

      while all('#titletwn', text: estate.name).count == 0 do
        within('div#cssdrivemenu1') do
          while true
            dropdown = page.all(:xpath, details_dropdown)

            if dropdown.count > 0
              dropdown.first.trigger(:mouseover)
              break
            end
          end

          link = find_link(estate.name)
          # link['onclick'].should == "goFlats('../../13MAYSBF_page_5789/$file/map.htm?open&ft=sbf&twn=GL')"

          link.click
        end
      end

      within_frame 'fda' do
        flat_types = page.all(:xpath, "//select[@name='Flat']/option")
        # flat_types.count.should == 5

        flat_types.map(&:text).each do |flat_type|
          # next unless flat_type.starts_with? '5'

          puts "Type: #{flat_type}"
          select flat_type, from: 'select7'

          click_button 'Search'
          sleep 5

          within_frame 'search' do
            # block_nos = page.all(:xpath, "//strong[contains(.,'Click on block no')]/ancestor::tr[1]/following-sibling::tr//a")
            loop do
              block_divs = page.all(:xpath, "//strong[contains(.,'Click on block no')]/ancestor::tr[1]/following-sibling::tr//a/div")

              @block_links = block_divs.map do |b|
                id = b[:id]
                no = page.find(:xpath, "//div[@id='#{id}']/ancestor::a[1]")
                street = page.find(:xpath, "//div[@id='#{id}']//font").text
                [no.text(:visible), street, no[:href]]
              end

              break if @block_links.count > 0
            end

            puts "Blocks: #{@block_links.count}"

            @block_links.each do |link|
              puts link[1], link.last

              expected_state = %Q{
                //strong[contains(.,'Click on block no')]/ancestor::tr[1]/following-sibling::tr
                //b[contains(.,'#{link.first}')]
                //font[contains(.,\"#{link[1]}\")]
              }

              loop do
                begin
                  while all(:xpath, expected_state).count == 0
                    page.execute_script(link.last)
                    sleep 2
                  end
                rescue Exception => error
                  # p error
                end
                break if error.nil?
              end

              block_info = ['Block','Street','Probable Completion Date', 'Delivery Possession Date',
                'Lease Commencement Date'].map do |item|
                # puts "#{item}: #{find_block_info(item)}"
                find_block_info(item)
              end << estate.id

              quota_str = find_block_info('Available Ethnic Quota')

              block_hash = Hash[block_fields.zip(block_info)]
              block = Block.where(no: block_hash[:no], street: block_hash[:street]).first_or_create(block_hash)

              quota_info = parse_quota(quota_str) << flat_type << block.id
              quota_hash = Hash[quota_fields.zip(quota_info)]
              quota = Quota.where(flat_type: flat_type, block_id: block.id).first_or_create(quota_hash)
              # quota.update_attributes(quota_hash) # to update existing quotas with wrong values
              # p quota.inspect

              unit_nos = page.all(:xpath, "//td[contains(.,'Mouseover unit number')]/ancestor::table[1]/following-sibling::table//font")
              puts "Units: #{unit_nos.count}"

              unit_nos.map(&:text).each do |unit|
                unit_info = page.all(:xpath, "//font[contains(.,'#{unit}')]/ancestor::td[1]/div[1]//td")
                                .map(&:text).map{|v| v.gsub(/\D/,'').to_i} << flat_type << quota.id

                unit_hash = Hash[unit_fields.zip(unit_info)].merge!({quota_id: quota.id})
                unit = Unit.where(no: unit, block: block).first_or_create(unit_hash)
                p unit_info
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

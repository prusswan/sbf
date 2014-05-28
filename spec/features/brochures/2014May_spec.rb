require 'spec_helper'

describe "2014 May Brochure" do

  def sbf_link
    'http://esales.hdb.gov.sg/hdbvsf/eampu05p.nsf/0/14MAYSBF_page_2381/$file/about0_static.htm'
  end

  def search_link
    "http://services2.hdb.gov.sg/webapp/BP13INTV/BP13PFlatSearch.jsp?Town=#{URI.escape @current_estate}&Flat_Type=SBF&DesType=A&ethnic=Y&Flat=#{flat_code}&ViewOption=A&dteBallot=201405"
  end

  def details_dropdown
    "//div[@id='MenuBoxTop']//a[contains(@class,'t7')]"
  end

  def price_dropdown
    "//div[@id='MenuBoxTop']//a[contains(@class,'t8')]"
  end

  def find_block_info(item)
    text = item.split[0]
    page.find(:xpath, "//td[@class='textLabelNew' and contains(.,'#{text}')]/following-sibling::td[1]").text
  end

  def block_fields
    [:no, :street, :probable_date, :delivery_date, :lease_start, :estate_id]
  end

  def unit_fields
    [:price, :area, :flat_type]
  end

  def quota_fields
    ['malay','chinese','others','flat_type','block_id']
  end

  def parse_quota(quota_str)
    r = quota_str.match /(\d+)\D+(\d+)\D+(\d+)/
    r[1..3].map(&:to_i)
  end

  def title_font_color
    '#BF1D2C'
  end

  def flat_code
    h = {
      "2-Room" => "2-Room",
      "3-Room" => "3-Room",
      "4-Room" => "4-Room",
      "5-Room" => "5-Room",
      "Executive" => "EXECUTIVE"
    }
    h[@current_flat_type]
  end

  def unstuck
    p "unstucking.."

    visit sbf_link
    sleep 3

    while all('#titletwn', text: @current_estate).count == 0 do
      within('div#cssdrivemenu1') do
        while true
          dropdown = page.all(:xpath, details_dropdown)

          if dropdown.count > 0
            dropdown.first.trigger(:mouseover)
            break
          end
        end

        link = find_link(@current_estate)
        # link['onclick'].should == "goFlats('../../13MAYSBF_page_5789/$file/map.htm?open&ft=sbf&twn=GL')"

        link.trigger('click')
      end
    end

    # page.execute_script @current_estate_link

    within_frame 'fda' do
      begin
        p @current_flat_type
        # visit search_link

        select @current_flat_type, from: 'select7'
        click_button 'Search'
      rescue Capybara::Poltergeist::JavascriptError
      end
      sleep 5
    end
  end

  before do
    visit sbf_link
    sleep 3
    p "THE PAGE"
    p page.current_url

#                   page.evaluate_script <<-SCRIPT
# function checkBlk(value, neigh, contract) {
#   document.forms[0].Block.value = value;
#   document.forms[0].Neighbourhood.value = neigh;
#   document.forms[0].Contract.value = contract;

#   document.forms[0].action="BP13EBSBULIST4";
#   document.forms[0].method="post";
#   document.forms[0].submit();

#   goblock(neigh, contract);
# }
#                  SCRIPT

  end

  it "load details page" do
    Estate.all.each do |estate|
      puts "Estate: #{estate.name}"
      @current_estate = estate.name

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
          @current_estate_link = link['onclick']
          link.click
        end
      end

      within_frame 'fda' do
        flat_types = page.all(:xpath, "//select[@name='Flat']/option")
        # flat_types.count.should == 5

        flat_types.map(&:text).each do |flat_type|
          # next unless flat_type.starts_with? '5'
          # next if flat_type.starts_with? 'S'

          puts "Type: #{flat_type}"
          @current_flat_type = flat_type

          begin
            # visit search_link

            select flat_type, from: 'select7'
            click_button 'Search'
          rescue Capybara::Poltergeist::JavascriptError
          end
          sleep 5
          # find_button("Search").trigger('click')

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
            @current_link_index = 0


            while @current_link_index < @block_links.count do
              link = @block_links[@current_link_index]
              # @block_links.each do |link|
              puts link[1], link.last

              expected_state = %Q{
                //strong[contains(.,'Click on block no')]/ancestor::tr[1]/following-sibling::tr
                //b[contains(.,'#{link.first}')]
                //font[contains(.,\"#{link[1]}\")]
              }

              iteration = 0
              state_count = 0

              loop do
                begin
                  state_count = all(:xpath, expected_state).count
                  while state_count == 0 and iteration <= 5
                    page.execute_script(link.last)
                    sleep(1 + iteration)
                    iteration = iteration + 1
                    p "iteration: #{iteration}"
                  end
                rescue Exception => error
                  # p error
                  break

                end

                iteration = iteration + 1
                break if error.nil? or iteration > 5
              end

              if state_count == 0
                p "we are stuck"
                p @current_estate
                p @current_flat_type
                p @current_link_index

                unstuck
                next
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

              @current_link_index = @current_link_index + 1

              sleep (unit_nos.count/10 + 1)
            end

            sleep (@block_links.count/10 + 1)
          end
        end
      end
    end
  end

  it 'loads intro page' do
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

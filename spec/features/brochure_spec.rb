require 'spec_helper'

describe "BrochureSpecs" do
  sbf_link = 'http://esales.hdb.gov.sg/hdbvsf/eampu05p.nsf/3ccada7e5293fd9748256e990029b104/13MAYSBF_page_5789/$file/about0_static.htm'
  details_dropdown = "//div[@id='MenuBoxTop']//a[@class='t7']"

  block_fields = [:no, :street, :probable_date, :delivery_date, :lease_start, :ethnic_quota, :estate]
  unit_fields = [:price, :area, :flat_type]

  flat_supply = {
    'Ang Mo Kio' => 57,
    'Geylang'    => 102
  }

  def find_block_info(item)
    text = item.split[0]
    page.find(:xpath, "//td[@class='textLabelNew' and contains(.,'#{text}')]/following-sibling::td[1]").text
  end

  it "load SBF main page" do
    visit sbf_link
    sleep 1

    flat_supply.keys.each do |estate|
      puts "Estate: #{estate}"
      next if Block.where(estate: estate).map(&:units).flatten.count == flat_supply[estate]


      while all('#titletwn', text: estate).count == 0 do
        within('div#cssdrivemenu1') do
          while true
            dropdown = page.all(:xpath, details_dropdown)

            if dropdown.count > 0
              dropdown.first.trigger(:mouseover)
              break
            end
          end

          link = find_link(estate)
          # link['onclick'].should == "goFlats('../../13MAYSBF_page_5789/$file/map.htm?open&ft=sbf&twn=GL')"

          link.click
        end
      end

      within_frame 'fda' do
        flat_types = page.all(:xpath, "//select[@name='Flat']/option")
        # flat_types.count.should == 5

        flat_types.map(&:text).each do |flat_type|
          puts "Type: #{flat_type}"
          select flat_type, from: 'select7'

          click_button 'Search'
          sleep 1

          within_frame 'search' do
            block_nos = page.all(:xpath, "//strong[contains(.,'Click on block no')]/ancestor::tr[1]/following-sibling::tr//a")

            block_links = block_nos.map { |b| [b.text(:visible), b[:href]] }
            puts "Blocks: #{block_nos.count}"

            block_links.each do |link|
              page.execute_script(link.last)

              page.find(:xpath, "//strong[contains(.,'Click on block no')]/ancestor::tr[1]/following-sibling::tr//b[contains(.,'#{link.first}')]")

              block_info = ['Block','Street','Probable Completion Date', 'Delivery Possession Date',
                'Lease Commencement Date', 'Available Ethnic Quota'].map do |item|
                # puts "#{item}: #{find_block_info(item)}"
                find_block_info(item)
              end << estate

              block_hash = Hash[block_fields.zip(block_info)]
              block = Block.where(no: block_hash[:no], street: block_hash[:street]).first_or_create(block_hash)

              unit_nos = page.all(:xpath, "//td[contains(.,'Mouseover unit number')]/ancestor::table[1]/following-sibling::table//font")
              puts "Units: #{unit_nos.count}"

              unit_nos.map(&:text).each do |unit|
                unit_info = page.all(:xpath, "//font[contains(.,'#{unit}')]/following-sibling::div[1]//td")
                                .map(&:text) << flat_type

                unit_hash = Hash[unit_fields.zip(unit_info)]
                unit = Unit.where(no: unit, block: block).first_or_create(unit_hash)
              end
            end
          end
        end
      end
    end
  end
end

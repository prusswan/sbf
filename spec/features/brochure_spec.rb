require 'spec_helper'

describe "BrochureSpecs" do
  sbf_link = 'http://esales.hdb.gov.sg/hdbvsf/eampu05p.nsf/3ccada7e5293fd9748256e990029b104/13MAYSBF_page_5789/$file/about0_static.htm'
  details_dropdown = "//div[@id='MenuBoxTop']//a[@class='t7']"

  def find_block_info(item)
    text = item.split[0]
    page.find(:xpath, "//td[@class='textLabelNew' and contains(.,'#{text}')]/following-sibling::td[1]").text
  end

  it "load SBF main page" do
    visit sbf_link
    sleep 1

    within('div#cssdrivemenu1') do
      while not page.current_url.end_with?('&twn=GL') do
        while true
          dropdown = page.all(:xpath, details_dropdown)

          if dropdown.count > 0
            dropdown.first.trigger(:mouseover)
            break
          end
        end

        link = find_link('Geylang')
        link['onclick'].should == "goFlats('../../13MAYSBF_page_5789/$file/map.htm?open&ft=sbf&twn=GL')"

        link.click
      end
    end

    within_frame 'fda' do
      # puts page.body
      flat_types = page.all(:xpath, "//select[@name='Flat']/option")
      flat_types.count.should == 5

      select flat_types[1].text, from: 'select7'

      click_button 'Search'
      sleep 1

      within_frame 'search' do
        block_nos = page.all(:xpath, "//strong[contains(.,'Click on block no')]/ancestor::tr[1]/following-sibling::tr//a")

        block_links = block_nos.map { |b| [b.text(:visible), b[:href]] }
        puts block_nos.count

        block_links.each do |link|
          page.execute_script(link.last)

          page.find(:xpath, "//strong[contains(.,'Click on block no')]/ancestor::tr[1]/following-sibling::tr//b")
          # puts page.body

          page.find(:xpath, "//td[@class='textContentNew' and contains(.,'#{link.first}')]")

          ['Block','Street','Probable Completion Date', 'Delivery Possession Date',
            'Lease Commencement Date', 'Available Ethnic Quota'].each do |item|
            puts "#{item}: #{find_block_info(item)}"
          end

          unit_nos = page.all(:xpath, "//td[contains(.,'Mouseover unit number')]/ancestor::table[1]/following-sibling::table//font")

          # puts page.body
          puts "Units: #{unit_nos.count}"
          unit_nos.map(&:text).each do |unit|
            unit_info = page.all(:xpath, "//font[contains(.,'#{unit}')]/following-sibling::div[1]//td")
            puts unit
            puts unit_info.map(&:text)
          end
        end
      end
    end
  end
end

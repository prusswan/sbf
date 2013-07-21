require 'spec_helper'

describe "BrochureSpecs" do
  sbf_link = 'http://esales.hdb.gov.sg/hdbvsf/eampu05p.nsf/3ccada7e5293fd9748256e990029b104/13MAYSBF_page_5789/$file/about0_static.htm'
  details_dropdown = "//div[@id='MenuBoxTop']//a[@class='t7']"

  describe "GET /brochure_specs" do
    it "load SBF main page" do
      visit sbf_link

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
          # block_nos = page.all(:xpath, "//td[descendant::strong]")

          block_nos = page.all(:xpath, "//tr[td[div[font[strong[contains(.,'Click on block no')]]]]]/following-sibling::tr//a")

          links = block_nos.map { |b| [b.text, b[:href]] }
          puts block_nos.count

          links.each do |link|
            page.execute_script(link.last)

            page.find(:xpath, "//tr[td[div[font[strong[contains(.,'Click on block no')]]]]]/following-sibling::tr//b")
            # puts page.body

            page.find(:xpath, "//td[@class='textContentNew' and contains(.,'#{link.first}')]")
            unit_nos = page.all(:xpath, "//table[tbody[tr[td[contains(.,'Mouseover unit number')]]]]/following-sibling::table//font")

            # puts page.body
            puts "#{link.first} #{unit_nos.count}"
          end
        end
      end
    end
  end
end

require 'spec_helper'

describe "BusstopSpecs" do
  it 'fetches kml data from pt.sg' do
    (1..1000).each do |n|
      path ='http://www.publictransport.sg/kml/busstops/busstops-kml-%d.kml' % n
      name = File.basename(path)
      dest_name ="lib/kml/#{name}"
      next if File.exist?(dest_name)

      begin
        xml = Nokogiri::XML(open(path))
        if xml.at('Placemark')
          begin
            File.open(dest_name,'w') {|f| xml.write_xml_to f}
          rescue Exception => e
            puts e
          end
        else
          puts "no data for #{n}"
        end
      rescue
        puts "not found for #{n}"
      end
    end
  end
end

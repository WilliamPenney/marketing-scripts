#PROXY = 'http://cdhwg01.prod.prv:80'
OUTPUT_FILENAME = 'airalo_pricing.csv'

require_relative 'utility'

def clean_country(c)

	c = c.downcase
	c = c.gsub(" ", "-") # replace space with hyphen
	c = c.gsub("'", "")  # remove apostrophe

	c = c.gsub(" (u.s.)", "") # remove (U.S.) from virgin islands

	if c.eql?("republic-of-the-congo")
		'congo'
	elsif c.eql?("swaziland")
		'eswatini'
	elsif c.end_with?('(hong-kong)')
		'hong-kong'
	elsif c.start_with?('iran')
		'iran-islamic-republic-of'
	elsif c.end_with?('(macau)')
		'macau'
	elsif c.eql?("saint-martin")
		c + 'french-part'
	elsif c.start_with?("virgin-islands")
		'virgin-islands'
	else
		c
	end

end




def parse_country(url, display_name, page_name)
	puts [display_name, page_name].to_s
	p = nil
	packages = Array.new
	# open page
	begin
		puts url.green
		p = open(url.downcase)
	rescue => e
		puts e.message.red
	end
	# parse using Nokogiri
	doc = Nokogiri::HTML(p)
	not_found = false
	doc.css('h2').each do |h2|
		text = h2.inner_html.strip
		if text.eql?("Popular Countries")
			not_found = true
		end
	end
	if not_found
		puts "#{display_name} not found".red
	else
		# find each span class="accordion-card-item"
		doc.css('.accordion-card-item').each_with_index do |element, i|
			package = Array.new
			package << display_name
			package << page_name
			#puts element.to_s.blue
			element.css('.card-header-main').each do |text|
				plan_name = text.inner_html.strip
				package << plan_name
			end
			element.css('.value-text').each do |text|
				# size and duration
				package << text.inner_html
			end
			# price
			element.css('.call-to-action').each do |text|
				price = text.inner_html.strip.split(' ').first[2..-1]
				package << price
			end
			packages << package
		end
	end
	packages
end



def parse_countries
	file_name = 'countries.csv'
	file = open(file_name)
	rows = CSV.open(file).to_a
	rows = rows.reject { |r| r.count.zero? }
	packages = Array.new
	rows.each do |row|
		sleep 2.5 + rand() # 2.5 to 3.5
		display_name = row.first
		page_name = clean_country(display_name)
		url = 'https://www.airalo.com/' + page_name + '-esim'
		packages += parse_country(url, display_name, page_name)
	end
	packages
end


def transform(packages)
	packages.each_with_index do |package, i|
		
		size = package[3]
		duration = package[4]
		price = package[5]

		# normalize to GB
		if size.include?('500 MB')
			packages[i][3] = "0.5 GB"
		end

		# remove " GB" from all sizes
		packages[i][3] = size.split(' ').first

		# remove  " days" from duration
		packages[i][4] = duration.split(' ').first.to_i # days

		# remove dollar sign from price
		packages[i][5] = price.gsub('$', '')

	end
	packages
end

t1 = Time.now
packages = parse_countries
packages = transform(packages)
header = ['Country Name', 'URL Parameter', 'Plan name', 'Size (GB)', 'Duration (Days)', 'Price USD']
save_packages(header, packages, OUTPUT_FILENAME)
puts "Runtime: " + (Time.now - t1).round.to_s + " seconds"
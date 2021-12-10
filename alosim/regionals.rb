PROFIT = 0.0

require_relative 'utility'
require_relative 'package'

def package_rate_cutoff(package_name)
	case package_name
		when 'UK and Ireland' 	then nil
		when 'Western Europe'	then nil
		when 'Scandanavia' 		then nil
		when 'Eastern Europe'	then 0.0034
		when 'Mediterranean'	then 0.0037
		when 'Caribbean'		then nil
		when 'South America'	then nil
		when 'Australia and NZ'	then nil
		when 'Asia'				then 0
		else nil
	end
end

def regional_imsip(package_name)
	case package_name
		when 'UK and Ireland' 	then 25
		when 'Western Europe'	then 25
		when 'Scandanavia' 		then 25
		when 'Eastern Europe'	then 25
		when 'Mediterranean'	then 25
		when 'Caribbean'		then 2
		when 'South America'	then 22
		when 'Australia and NZ'	then 10
		when 'Asia'				then 10
		when 'Asia Five Pack'	then 10
	end
end

def regional_packages

	regionals = Hash.new

	regionals['UK and Ireland'] = Array.new
	regionals['UK and Ireland'] << 'United Kingdom'
	regionals['UK and Ireland'] << 'Ireland'

	regionals['Western Europe'] = Array.new
	regionals['Western Europe'] << 'France'
	regionals['Western Europe'] << 'Italy'
	regionals['Western Europe'] << 'Portugal'
	regionals['Western Europe'] << 'Spain'

	regionals['Scandanavia'] = Array.new
	regionals['Scandanavia'] << 'Norway'
	regionals['Scandanavia'] << 'Sweden'
	regionals['Scandanavia'] << 'Finland'
	regionals['Scandanavia'] << 'Denmark'

	regionals['Eastern Europe'] = Array.new
	regionals['Eastern Europe'] << 'Bulgaria'
	regionals['Eastern Europe'] << 'Croatia'
	regionals['Eastern Europe'] << 'Austria'
	regionals['Eastern Europe'] << 'Czech Republic'
	regionals['Eastern Europe'] << 'Hungary'
	regionals['Eastern Europe'] << 'Slovakia'
	regionals['Eastern Europe'] << 'Poland'
	regionals['Eastern Europe'] << 'Ukraine'
	regionals['Eastern Europe'] << 'Romania'
	regionals['Eastern Europe'] << 'Lithuania'
	regionals['Eastern Europe'] << 'Latvia'
	regionals['Eastern Europe'] << 'Estonia'
	regionals['Eastern Europe'] << 'Greece'
	regionals['Eastern Europe'] << 'Belarus'
	regionals['Eastern Europe'] << 'Serbia'

	regionals['Mediterranean'] = Array.new
	regionals['Mediterranean'] << 'Spain'
	regionals['Mediterranean'] << 'France'
	regionals['Mediterranean'] << 'Italy'
	regionals['Mediterranean'] << 'Croatia'
	regionals['Mediterranean'] << 'Albania'
	regionals['Mediterranean'] << 'Greece'
	regionals['Mediterranean'] << 'Turkey'
	regionals['Mediterranean'] << 'Montenagro'

	# Carib 2
	regionals['Caribbean'] = Array.new
	regionals['Caribbean'] << 'Saint Lucia'
	regionals['Caribbean'] << 'Turks and Caicos'
	regionals['Caribbean'] << 'Anguilla'
	regionals['Caribbean'] << 'British Virgin Islands'
	regionals['Caribbean'] << 'Antigua and Barbuda'
	regionals['Caribbean'] << 'Bahamas'
	regionals['Caribbean'] << 'Barbados'
	regionals['Caribbean'] << 'Cayman Islands'
	regionals['Caribbean'] << 'Puerto Rico'
	regionals['Caribbean'] << 'Saint Kitts and Nevis'
	regionals['Caribbean'] << 'Saint Vincent'
	regionals['Caribbean'] << 'Jamaica' 					# requires whitelist of 2 because country is set to 22 (SA) due to cost

	# Asia 22
	regionals['South America'] = Array.new
	regionals['South America'] << 'Bolivia'
	regionals['South America'] << 'Ecuador'
	regionals['South America'] << 'French Guiana'
	regionals['South America'] << 'Uruguay'
	regionals['South America'] << 'Paraguay'				# requires whitelist of 22 (3G) because country is set to 10 (Asia, because it has LTE)
	regionals['South America'] << 'Argentina'
	regionals['South America'] << 'Brazil'
	regionals['South America'] << 'Chile'
	regionals['South America'] << 'Colombia'
	regionals['South America'] << 'Peru'

	# Asia 10

	regionals['Australia and NZ'] = Array.new
	regionals['Australia and NZ'] << 'Australia'
	regionals['Australia and NZ'] << 'New Zealand'


	regionals['Asia Five Pack'] = Array.new
	regionals['Asia Five Pack'] << 'South Korea'
	regionals['Asia Five Pack'] << 'Malaysia'
	regionals['Asia Five Pack'] << 'Taiwan'
	regionals['Asia Five Pack'] << 'Thailand'
	regionals['Asia Five Pack'] << 'Hong Kong'

	regionals['Asia'] = Array.new
	regionals['Asia'] << 'Bhutan'
	regionals['Asia'] << 'Laos'
	regionals['Asia'] << 'Tajikistan'
	regionals['Asia'] << 'Nepal'
	regionals['Asia'] << 'Mongolia'
	regionals['Asia'] << 'Armenia'
	regionals['Asia'] << 'Japan'
	regionals['Asia'] << 'Bangladesh'
	regionals['Asia'] << 'Macao'
	regionals['Asia'] << 'Azerbaijan'
	regionals['Asia'] << 'Vietnam'
	regionals['Asia'] << 'Brunei'
	regionals['Asia'] << 'Singapore'
	regionals['Asia'] << 'Philippines'
	regionals['Asia'] << 'China'
	regionals['Asia'] << 'Myanmar'
	regionals['Asia'] << 'Sri Lanka'
	regionals['Asia'] << 'Cambodia'
	regionals['Asia'] << 'India'
	regionals['Asia'] << 'Indonesia'
	regionals['Asia'] << 'Hong Kong'
	regionals['Asia'] << 'Malaysia'
	regionals['Asia'] << 'South Korea'
	regionals['Asia'] << 'Taiwan'
	regionals['Asia'] << 'Thailand'
	regionals['Asia'] << 'Uzbekistan'
	regionals['Asia'] << 'Nauru'
	regionals['Asia'] << 'Papua New Guinea'
	regionals['Asia'] << 'Samoa'
	regionals['Asia'] << 'Tonga'
	regionals['Asia'] << 'Guam'
	regionals['Asia'] << 'Fiji'
	regionals['Asia'] << 'Australia'
	regionals['Asia'] << 'New Zealand'

	regionals

end

whitelist = Array.new
packages = Array.new

offerings = load_offerings
mappings = Hash.new

regional_packages.each do |package_name, countries|

	puts ''
	imsip = regional_imsip(package_name)
	puts package_name.green
	puts imsip.to_s.green

	mappings[package_name] = Array.new

	if imsip.nil?
		puts "Missing IMSIP for #{package_name}".red
		sleep 3
	else

		p_offerings = Array.new

		countries.each do |c|

			# find all offerings with this imsip
			c_offerings = offerings.select { |o| o[1] == c and o[2] == imsip }
			
			if c_offerings.any?
				c_offerings = c_offerings.sort { |a, b| a[4] <=> b[4] }
				best_rate = c_offerings.first[4]
				rate_ceiling = best_rate * (1 + QUALITY_WILLINGNESS)
				c_offerings = c_offerings.select { |op| op[4] <= rate_ceiling }
				p_offerings += c_offerings
			else
				offerings = load_offerings("3G")
				if c_offerings.any?
					puts "#{c} selecting 3G mode".yellow
					c_offerings = c_offerings.sort { |a, b| a[4] <=> b[4] }
					best_rate = c_offerings.first[4]
					rate_ceiling = best_rate * (1 + QUALITY_WILLINGNESS)
					c_offerings = c_offerings.select { |op| op[4] <= rate_ceiling }
					p_offerings += c_offerings
				else
					puts "#{c} No 3G or LTE available for IMSIP #{imsip}".red
				end
			end

		end

		cutoff = package_rate_cutoff(package_name)
		if cutoff.nil?
			puts "No cutoff found. Selecting all countries listed in this package"
		else
			p_offerings = p_offerings.select { |o| o[4] <= cutoff }
		end

		# sort by rate
		p_offerings = p_offerings.sort { |a, b| a[4] <=> b[4] }
		p_offerings.each { |p| puts [p[1], p[4]].to_s }
		
		if p_offerings.any?

			# highest rate
			rate_min = p_offerings.first[4]
			rate_max = p_offerings.last[4]
			ratio = rate_max.to_f / rate_min.to_f
			print "Rate range: "
			puts [rate_min, rate_max, ratio.round(3)].to_s

			operator_count = p_offerings.count

			telna_rate = rate_max

			# create package
			SIZES.each do |size|
				breakage = breakage_lookup(size)
				variable_cost = telna_rate * 1024 * size * (1 - breakage)
				fixed_cost = 0.95
				raw_cost = ((variable_cost + fixed_cost) * (1 + STRIPE_FEE)).round(2)
				price = raw_cost * (1 + PROFIT)

				if price < 9
					price = ((price * 4).round.to_f / 4).round(2)
				elsif price < 25
					price = ((price * 2).round.to_f / 2).round(2)
				else
					price = price.round
				end

				profit = price.nil? ? nil : (price - raw_cost) / raw_cost
				duration = duration_lookup(size)

				output = [package_name, imsip, operator_count, rate_min, rate_max, ratio.round(3), size, duration, breakage, raw_cost, price, profit.round(3)]
				puts output.to_s
				packages << output
			end

			# add to white list
			p_offerings.each do |o|

				country = o[1]

				output = [ package_name, o[0], country, o[2], o[3], o[4], o.last ]
				# puts output.to_s
				whitelist << output

				# add to mapping list
				mappings[package_name] << country

			end

			mappings[package_name] = mappings[package_name].uniq.sort

		else

			puts "#{package_name} no offerings found".red

		end

	end

end

header = ["Package name", "IMSIP", "# Operators", "Min Rate", "Max Rate", "Max/Min Ratio", "Size", "Duration", "Breakage assumption", "Raw_Cost", "Price", "Profit"]
save_rows(header, packages, 'alosim_regional_packages.csv')

header = ["Package name", "Region", "Country", "IMSIP", "Operator", "Rate", "VPMN" ]
save_rows(header, whitelist, 'alosim_regional_whitelist.csv')


mappings.each do |p_name, countries|
	imsip = regional_imsip(p_name)
	puts ''
	puts "Package: #{p_name} (IMSIP #{imsip})".blue
	puts "-------------------------------------".blue
	puts countries
end
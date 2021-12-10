# Telna Offerings
# Africa;Algeria;IMSI 22;Algerie Telecom Mobile;0.009200;9.420800
# 0 - Region
# 1 - Country
# 2 - IMSIP
# 3 - Operator
# 4 - Rate
# 5 - 2G
# 6 - 3G
# 7 - LTE
# 8 - VPMN

# Airolo
# Country Name,URL Parameter,Plan name,Size (GB),Duration (Days),Price USD
# 0 - Country
# 3 - Size
# 4 - Duration
# 5 - Price

OUTPUT_FILENAME = 'alosim_pricing_test.csv'
WHITE_LIST_OUTPUT_FILENAME = 'alosim_country_whitelist_test.csv'

RENEWAL_RATE = 0.05

IMSI_PROFILE = [2, 10, 22, 25, 26]

require_relative 'utility'
require_relative 'package'

# load Telna offerings
offerings = load_offerings

# load airalo pricing
file = open('airalo_pricing.csv')
airalo = CSV.open(file, { col_sep: ',' }).to_a

airalo_unlimited_countries = airalo.select { |r| r[3].eql?('Unlimited') }.map { |r| r.first }

airalo = airalo.select { |r| r[3] != ('Unlimited') }
airalo.each_with_index do |r, i|
	airalo[i][3] = airalo[i][3].to_f
	airalo[i][4] = airalo[i][4].to_f
	airalo[i][5] = airalo[i][5].to_f
end

# load country visits
file = open('country_arrivals.csv')
country_arrivals = CSV.open(file, { col_sep: ',' }).to_a.to_h

# initialize a few things
packages = Array.new
whitelist = Array.new

countries = offerings.map { |r| r[1] }.uniq.sort

countries = ['Canada']

countries.each_with_index do |c, i|

	#puts c.blue

	airalo_unlimited = airalo_unlimited_countries.include?(c)

	# select all offerings for the country
	c_operators = offerings.select { |op| op[1].eql?(c) }

	if c_operators.any?

			# select offerings using IMSIP that are programmed for direct routing
			logical_routing_operators = c_operators.select { |op| regional_routing?(op) }

			if logical_routing_operators.any?
				
				sorted = logical_routing_operators.sort { |a, b| a[4] <=> b[4] }
				best = sorted.first
				rate = best[4]
				rate_ceiling = rate * (1 + QUALITY_WILLINGNESS)
				competitive_offerings = logical_routing_operators.select { |op| op[4] <= rate_ceiling }
				uniq_imsips = competitive_offerings.map { |w| w[2] }.uniq

				if uniq_imsips.count > 1

					# there is more than one unique IMSIP within the competitive offerings
					# check for manual routing

					imsip = manual_routing(c)
					if imsip.nil?
						puts "Manual routing needed for #{c}".red
						sleep 3
					else
						competitive_offerings = competitive_offerings.select { |op| op[2] == imsip }
						sorted = competitive_offerings.sort { |a, b| a[4] <=> b[4] } # by price
						best = sorted.first
						rate = best[4]
						rate_ceiling = rate * (1 + QUALITY_WILLINGNESS)
						competitive_offerings = logical_routing_operators.select { |op| op[4] <= rate_ceiling }
						coverage = competitive_offerings.count
						c_packages = create_packages("Manual", c, best, coverage, airalo, country_arrivals, airalo_unlimited)
						packages += c_packages	
					end

				else
					coverage = competitive_offerings.count
					c_packages = create_packages("Local", c, best, coverage, airalo, country_arrivals, airalo_unlimited)
					packages += c_packages
				end

				whitelist += competitive_offerings.map { |r| ['Country', r[0], r[1], r[2], r[3], r[4], r[8]] }

			else
				
				# use lowest cost routing
				cost_routing_operators = c_operators - regional_routing_operators
				sorted = cost_routing_operators.sort { |a, b| a[4] <=> b[4] }
				best = sorted.first
				rate = best[4]
				rate_ceiling = rate * (1 + QUALITY_WILLINGNESS)
				competitive_offerings = cost_routing_operators.select { |op| op[4] <= rate_ceiling }
				uniq_imsips = competitive_offerings.map { |w| w[2] }.uniq
				
				coverage = competitive_offerings.count

				whitelist += competitive_offerings.map { |r| ['Country', r[0], r[1], r[2], r[3], r[4], r[8]] }

				if uniq_imsips.count.zero?

					puts "Zero offerings for #{c}".red
					sleep 1

				elsif uniq_imsips.count > 1
					
					# check manual routing
					imsip = manual_routing(c)
					if imsip.nil?
						3.times.each { puts "Need manual routing for #{c}".red }
					else
						puts "#{c} choosing IMSIP #{imsip}".green
						manual_routing_operators = competitive_offerings.select { |o| o[2] == imsip }
						sorted = cost_routing_operators.sort { |a, b| a[4] <=> b[4] }
						best = sorted.first
						packages += create_packages("Manual", c, best, coverage, airalo, country_arrivals, airalo_unlimited)

					end

				else
					packages += create_packages("Cost", c, best, coverage, airalo, country_arrivals, airalo_unlimited)
				end
			end

	else

		puts "#{c} No offerings found".red
		sleep 1

	end

end

# packages += create_packages("IMSIP match", c, best_offering, rate_tie, competition_offers, country_arrivals)
header = ["PGW routing method", "Region", "Country", "IMSIP", "Operator", "Speed", "Telna rate per MB", "Coverage", "Size (GB)", "Duration (days)", "Breakage", "Raw cost", "Airalo price", "Raw vs Airalo", "Airalo price per GB", "Airalo unl. country ?", "Airalo extrapolated ?", "Yearly travelers (millions)", "Strategy", "Price", "Profit"]

# save output to CSV file
save_rows(header, packages, OUTPUT_FILENAME)

# save whitelist
save_rows(["Type", "Region", "Country", "IMSIP", "Operator", "Rate", "VPMN"], whitelist, WHITE_LIST_OUTPUT_FILENAME)
# this is called by price.rb

SIZES = [1, 3, 5, 10]
TARGET_MARGIN = 0.3
STRIPE_FEE = 0.03
MAX_RAW_VS_AIRALO_RATIO = 2.9

def create_packages(mode, country, best_offering, coverage, competition_offers, country_arrivals, airalo_unlimited)

	packages = Array.new

	c = country

	telna_region = best_offering[0]
	imsip        = best_offering[2]
	operator     = best_offering[3]
	telna_rate   = best_offering[4].to_f
	speed 		 = fastest_speed(best_offering)

	SIZES.each do |size|

		size = size.to_f.round(1)
		duration = duration_lookup(size)

		# find competiting price based on same size and duration
		competition = lookup_competing_price(competition_offers, c, size, duration)

		# extrapolate competiting price based on 1GB size
		competing_price = nil
		extrapolated = false
		airalo_price_per_gb = nil

		if competition.nil?

			#print "No competition pricing for #{c} and #{size}"
			#print " (unlimited country)" if airalo_unlimited
			#puts  ""

			# try to create the size using smaller packages
			total_size = 0
			
			airalo_country = translate_telna_country_to_airalo(country)
			country_packages = competition_offers.select { |a| a.first == airalo_country }
			country_packages.sort! { |a, b| b[3] <=> a[3] } # ordered by size descending

			package_index = 0
			total_price = 0
 
 			if country_packages.any?
 				#puts "Found #{country_packages.count} packages for #{country}"
 				#puts country_packages.to_s
				# iterate from largest size to smallest size
				loop do

					remaining_size = size - total_size
					airalo_size = country_packages[package_index][3]

					#puts [airalo_size, remaining_size].to_s.yellow

					if airalo_size <= remaining_size.to_f.round(1)
						#sleep 0.002
						#puts "Size of comparison package #{country_packages[package_index][3]}"
						#puts "Remaining size #{remaining_size}"
						total_size  += country_packages[package_index][3].to_f
						total_price += country_packages[package_index][5].to_f
						#puts [total_size, total_price].to_s.blue
						# check for exit condition
						if total_size == size
							competing_price = total_price
							extrapolated = true
							break
						end
					else
						# advance to next largest package size
						package_index += 1
					end

					if package_index == country_packages.count
						#puts "Ran out of country packages for #{country}".yellow
						#sleep 2
						break 	
					end

				end 
			else
				#puts "No packages found for #{country} period; cannot extrapolate".red
			end

		else

			competing_price = competition[5].to_f.round(2)

		end

		# calculate cost
		breakage = breakage_lookup(size)
		variable_cost = telna_rate * 1024 * size * (1 - breakage)
		fixed_cost = 0.95
		raw_cost = ((variable_cost + fixed_cost) * (1 + STRIPE_FEE)).round(2)

		# compare with competition
		raw_vs_airalo = nil
		target = nil

		if competing_price.nil? # no competition

			if raw_cost > 120 # dollars
				strat = :Suppress
				price = nil
			else
				strat = :Profit
				price = (raw_cost * 1.3).round(0)
			end

		else
			airalo_price_per_gb = competing_price / size
			raw_vs_airalo = (raw_cost / competing_price).round(2)
			if raw_vs_airalo > MAX_RAW_VS_AIRALO_RATIO
				# we're too expensive
				strat = :Concede
				price = nil
			elsif raw_vs_airalo < 1
				# match their pricing
				strat = :Match
				price = competing_price
			else
				strat = :Cover
				# don't lose money
				price = raw_cost.ceil
			end
		end

		if manual_prices.key?(c) and manual_prices[c].key?(size.to_i)
			if manual_prices[c].key?(size.to_i).nil?
				strat = :Manual
				price = manual_prices[c][size.to_i]
			else
				strat = :Manual
				price = manual_prices[c][size.to_i]
			end
		end

		# computer profit
		profit = price.nil? ? nil : (price - raw_cost) / raw_cost

		# merge traveller data
		n_arrivals = ''
		if country_arrivals.key?(c)
			n_arrivals = (country_arrivals[c].to_i / 1000000.to_f).round(1)
		end		

		output = [mode, telna_region, c, imsip, operator, speed, telna_rate, coverage, size, duration, breakage, raw_cost, competing_price, raw_vs_airalo, airalo_price_per_gb, airalo_unlimited, extrapolated, n_arrivals, strat, price, profit]
		#puts output.to_s

		# add it to the stack
		packages << output

	end

	packages

end

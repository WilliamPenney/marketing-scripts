PARTNERS = ['Adwords', 'Apple']
M0_INDEX = 5

require_relative 'utility'

# load file
file = open('maturation.csv')
rows = CSV.open(file).to_a
rows = strip_header(rows)

=begin

	[0, "Date"]
	[1, "Partner"]
	[2, "W0"]
	[3, "M0"]
	[4, "M1"]
	.
	.
	.
	[33, "M30"]

=end

roass  = Hash.new
deltas = Hash.new

PARTNERS.each do |partner|

	#puts partner

	rows_partner = rows.select { |r| r[1].eql?(partner) }
	
	roass[partner]  = Hash.new
	deltas[partner] = Hash.new

	(0..45).each do |cohort|

		#puts cohort.to_s.green
		roass[partner][cohort] = Array.new
		deltas[partner][cohort] = Array.new
		
		rows_partner.each_with_index do |r, i|
		
			date = Date.parse(r.first)
			months = age(date)
		
			if months > cohort
				
				
				roas_b = r[M0_INDEX + cohort - 0]


				if roas_b.nil? or roas_b.to_f.zero?
					
					# can't do anything

				else
					
					#puts [date.to_s, roas_b].inspect

					roass[partner][cohort] << roas_b.to_f
					
					if cohort.zero?

						# no delta; take sum only (already done)

					else

						roas_a = r[M0_INDEX + cohort - 1]
						
						if roas_a.nil?
						
							# still no delta

						else

							# convert
							roas_a = roas_a.to_f
							roas_b = roas_b.to_f

							# take delta
							d = roas_b / roas_a - 1

							#puts [roas_a, roas_b, d].to_s

							if d < 0
								puts "This does not occur".red
							else
								if d > 0
									# expected
								else
									# no change
								end
								deltas[partner][cohort] << d
							end
						end
					end
				end

			else
				# not mature cannot use
			end
		end
	end
end

output = Array.new

PARTNERS.each do |partner|
	deltas[partner].each do |cohort, delta_values|
		mean_roas = mean(roass[partner][cohort])
		roas_count = roass[partner][cohort].count
		mean_delta = cohort.zero? ? nil : mean(delta_values)
		output << [partner, cohort, mean_roas, roas_count, mean_delta, delta_values.count]
	end
end

header = ['Partner', 'Cohort', 'Mean Roas', 'Mean Roas N. Samples', 'Mean Delta', 'Mean Delta N. Samples']

save_rows(header, output, 'maturation_report.csv')

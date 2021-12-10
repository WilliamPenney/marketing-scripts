# NB. Apple has no cost until 2019-07-22

#WINDOWS = [60, 30, 15, 10, 7, 5, 3, 1]

WINDOWS = [90, 30, 10, 7, 3, 1]

require_relative 'utility'
require_relative 'estimate'

# load file
file = open('adjust_12_05_weekly.csv')
data = CSV.open(file).to_a

# print header
header = data.shift

#header.each_with_index do |h, i|
#	puts [i, h].to_s
#end

=begin
	[0, "row_id"]
	[1, "date"]
	[2, "partner"]
	[3, "cost"]
	[4, "installs"]
	[5, "date-partner"]
	[6, "period"]
	[7, "revenue_total"]
	[8, "revenue_events_total"]
	[9, "paying_users"]
	[10, "cohort_size"]
=end

first_start_date = Date.parse("Jan. 1, 2021")

# filter data
data = data.select { |d| d[6].to_i.zero? }

output = Array.new

WINDOWS.each do |w|

	puts "\nWINDOW #{w}"

	last_start_date = Date.today - w - 6
	
	# generate values
	(first_start_date..last_start_date).each do |start_date|

		stop_date = start_date + w - 1

		puts start_date.to_s.yellow

		# select rows based on start and end dates
		rows_date = data.select { |d| Date.parse(d[1]) >= start_date and Date.parse(d[1]) <= stop_date }

		# total for all partners
		t_cost = 0
		t_rev  = 0

		unique_day_count = rows_date.map { |d| d[1] }.uniq.count
		complete = true # assume true

		# sub totals for Adwords and Apple
		["Adwords", "Apple"].each do |partner|

			rows_partner = rows_date.select { |d| d[2].eql?(partner.downcase) }
			unique_day_count = rows_partner.map { |r| r[1] }.uniq.count
			days_without_samples = w - unique_day_count

			# do we have cost for all days?
			# how many of them are non zero?

			costs = rows_partner.map { |d| d[3].to_f }
			days_without_cost = costs.select { |c| c.zero? }.count

			complete = false if days_without_cost > 0
			complete = false if days_without_samples > 0

			cost = rows_partner.map { |d| d[3].to_f }.inject(0, :+)
			rev  = rows_partner.map { |d| d[7].to_f }.inject(0, :+)

			roas = nil
			t_roas = nil
			ltv = [nil, nil, nil]

			if cost.zero?
				puts "#{start_date} WINDOW #{w} #{partner} - Cannot divide by zero".yellow
			else
				roas = rev / cost
				roas = roas.round(3)
				#ltv = estimate_ltv(roas, partner)

			end

			output << [start_date.to_s, stop_date.to_s, w, partner, rev.round(2), cost.round(2), days_without_cost, days_without_samples, roas, ltv].flatten

			# for creating total
			t_cost += cost
			t_rev  += rev

		end

		t_roas = nil
		if complete then
			t_roas = t_rev / t_cost
		else
			# leave roas as nil
		end

		output << [start_date.to_s, stop_date.to_s, w, 'Total', t_rev.round(2), t_cost.round(2), nil, nil, nil, nil].flatten

	end

end


# add jerome
#j = load_jerome

#w = 31

#j.each do |date, v|
#	output << [date.to_s, v[:stop], w, 'Total-J',   v[:rev], v[:cost], nil, nil, v[:roas], nil, nil, nil]
#	output << [date.to_s, v[:stop], w, 'Adwords-J', nil, nil, nil, nil, v[:roas_g], nil, nil, nil]
#	output << [date.to_s, v[:stop], w, 'Apple-J',   nil, nil, nil, nil, v[:roas_a], nil, nil, nil]
#end

header = ['Start Date', 'End Date', 'Window (days)', 'Partner', 'Revenue', 'Cost', 'Days without cost', 'Days without samples', 'W0 ROAS', 'M30 ROAS', 'M30 ROAS Sample Size', 'STDEV']

save_rows(header, output, "Adjust weekly.csv")
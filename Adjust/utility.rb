SPREAD = 0.07
IRR = 0.02

require 'colorize'
require 'open-uri'
require 'json'
require 'csv'



# ----------------------------------------------------------------------------        LOADING          ----------------------------

def load_jerome()
=begin
	[0, "Start Date"]
	[1, "Stop Date"]
	[2, "Cost"]
	[3, "Rev"]
	[4, "ROAS"]
	[5, "ROAS-G"]
	[6, "ROAS-A"]
	[7, "BE"]
=end	
	rows = load_csv('jerome.csv')
	rows = strip_header(rows)
	rows = rows.map { |r| [r.first, { stop: r[1], cost: r[2].to_f, rev: r[3].to_f, roas: r[4].to_f, roas_g: r[5].to_f, roas_a: r[6].to_f }] }.to_h
	rows
end

def load_csv(filename)
	file = open(filename)
	rows = CSV.open(file).to_a
end

def strip_header(rows, print_header = false)
	h = rows.shift
	print_header(h) if print_header
	rows
end

def print_header(h)
	h.each_with_index do |h, i|
		puts [i, h].to_s
	end
end

def save_rows(header, rows, filename)
	puts "Saving #{rows.count} rows"
	CSV.open(filename, "w") do |csv|
		csv << header
		rows.each do |r|
			csv << r
		end
	end
end


# ----------------------------------------------------------------------------        MATH / FINANCE          ----------------------------

def age(date = Date.parse("Jan 1, 2021"))
	((Date.today - date).to_i / 365.to_f * 12).floor
end

def npv(fv, periods, irr = IRR / 12)
	fv / ((1 + irr) ** periods)
end


def stdev(a)
	mean = mean(a) / a.count.to_f
	squared_differences = a.map { |r| (r - mean)**2 }
    variance = ( squared_differences.inject(0, :+) / a.count )
    stdev = variance ** 0.5
end

def mean(a)
	if a.nil? or a.include?(nil)
		nil
	else
		a.inject(0, :+) / a.count.to_f
	end
end

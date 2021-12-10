def update_currency_conversion
	url = 'https://www.bankofcanada.ca/valet/observations/group/FX_RATES_DAILY/json?start_date=2017-01-03'
	file = open(url)
	download = open(url)
	IO.copy_stream(download, 'currency_conversion.json')
	CSV.new(download).each do |l|
	   puts l
	end
end

def load_currency_conversion_rates
	file = File.read('currency_conversion.json')
	data_hash = JSON.parse(file)
	a = data_hash['observations'].map { |o| [o['d'], o['FXUSDCAD']['v']] }
	h = a.to_h
end

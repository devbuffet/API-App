module MoviesHelper
	require 'open-uri'
	# return web document
	def returnWebDocument(url)
		return Nokogiri::HTML(open(url)) 
	end
end

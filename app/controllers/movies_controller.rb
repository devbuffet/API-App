class MoviesController < ApplicationController
	include MoviesHelper
  skip_before_filter :verify_authenticity_token
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  # For all responses in this controller, return the CORS access control headers.
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.

  def cors_preflight_check
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
    headers['Access-Control-Max-Age'] = '1728000'
  end

  def list   
	# start off empty array
	arrURL = []

	# define URLs
	arrURL.push('http://www.zmovie.tw/movies/new')
	arrURL.push('http://www.zmovie.tw/movies/featured')
	arrURL.push('http://www.zmovie.tw/movies/recent')
	arrURL.push('http://www.zmovie.tw/movies/recent_update')
	arrURL.push('http://www.zmovie.tw/movies/top')

	# get the request
	request = arrURL[params[:request].to_i]
	search = params[:search].to_s.downcase

	# scrape url	
	doc = returnWebDocument(request)

	# start with empty array
	arrMovies = [] 

	doc.search('a').each do |row|
		if (row['href'].to_s.downcase.include? "http://www.zmovie.tw/movies/view")
			# find relevant links
			objects = arrMovies.select { |obj| obj.href == row['href'] } 
			if objects.size == 0 && !(row['href'].include? 'comments')
				img_src = "http://www.zmovie.tw/files/movies/" + row['href'].to_s.split('/')[5] + ".jpg"
				objMovie = Movie.new(row['title'],row['href'],img_src)
				arrMovies.push(objMovie)
			end 
		end	
	end	

	# set instance variable for view
	@arrMovies = arrMovies

	# filter movies
	@arrMovies = @arrMovies.select { |item| item.title.downcase.include? search }

	# return json
	render json: JSON.pretty_generate(@arrMovies)

end

# define movie class
class Movie
   attr_accessor :title, :href, :img_src
   def initialize(title, href, img_src)
      @title = title
      @href = href
      @img_src = img_src
   end
end

# define movie rating class
class MovieRating
   attr_accessor :href, :rating
   def initialize(href, rating)
      @href = href
      @rating = rating
   end
end
end

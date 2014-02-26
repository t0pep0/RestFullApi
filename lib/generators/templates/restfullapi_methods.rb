class <<RestFullApi::Methods
			def get_geo
				lat = @params[:lat]
				lng = @params[:lng]
				city = Geocoder.search([lat, lng]).first.city
				city_id = City.where(:title => city).first
				return nil if city_id.nil?
				return {:id => city_id.id, :title => city_id.title, :promo_url => city_id.promo_url}
			end
end

function ChangeHat( model, sender )
	sender:SetValue( "HatModel", model ) -- Store the hat as a player value
end

Network:Subscribe( "ChangeHat", ChangeHat )
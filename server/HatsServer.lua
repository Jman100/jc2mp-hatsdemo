function ChangeHat( model, sender )
	sender:SetNetworkValue( "HatModel", model ) -- Store the hat as a player value
end

Network:Subscribe( "ChangeHat", ChangeHat )
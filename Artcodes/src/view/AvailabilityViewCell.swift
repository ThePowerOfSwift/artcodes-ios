/*
 * Artcodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import ArtcodesScanner
import UIKit

class AvailabilityViewCell: UITableViewCell
{
	@IBOutlet weak var icon: UIImageView!
	@IBOutlet weak var title: UILabel!
	
	let shortFormatter = NSDateFormatter()
	let longFormatter = NSDateFormatter()
	let calendar = NSCalendar.currentCalendar()
	
	var index: Int!
	var viewController: AvailabilityListViewController!
	var availability: Availability!
	{
		didSet
		{
			update()
		}
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		shortFormatter.dateFormat = "d MMM"
		longFormatter.dateFormat = "d MMM y"
	}
	
	func update()
	{
		if availability.end == nil
		{
			if availability.start == nil
			{
				if availability.name != nil
				{
					title.text = "Available near " + availability.name!
					icon.image = UIImage(named: "ic_place")
				}
				else
				{
					title.text = "Public"
					icon.image = UIImage(named: "ic_public")
				}
			}
			else
			{
				if availability.name != nil
				{
					title.text = "Available from " + formatDate(availability.start!) + " near " + availability.name!
					icon.image = UIImage(named: "ic_place")
				}
				else
				{
					title.text = "Available from " + formatDate(availability.start!)
					icon.image = UIImage(named: "ic_schedule")
				}
			}
		}
		else if availability.start == nil
		{
			if availability.name == nil
			{
				title.text = "Available until " + formatDate(availability.end!) + " near " + availability.name!
				icon.image = UIImage(named: "ic_place")
			}
			else
			{
				title.text = "Available until " + formatDate(availability.end!)
				icon.image = UIImage(named: "ic_schedule")
			}
		}
		else
		{
			if availability.name != nil
			{
				title.text = "Available " + formatDateRange(availability.start!, end: availability.end!) + " near " + availability.name!
				icon.image = UIImage(named: "ic_place")
			}
			else
			{
				title.text = "Available " + formatDateRange(availability.start!, end: availability.end!)
				icon.image = UIImage(named: "ic_schedule")
			}
		}
	}
	
	func formatDate(timestamp: Int) -> String
	{
		let date = NSDate(timeIntervalSince1970: Double(timestamp) / 1000.0)
	    let currentYear = calendar.component(.Year, fromDate: NSDate())
		let year = calendar.component(.Year, fromDate: date)
		if year == currentYear
		{
			return shortFormatter.stringFromDate(date)
		}
		return longFormatter.stringFromDate(date)
	}
	
	func formatDateRange(start: Int, end: Int) -> String
	{
		let startDate = NSDate(timeIntervalSince1970: Double(start) / 1000.0)
		let endDate = NSDate(timeIntervalSince1970: Double(end) / 1000.0)
		let startComponents = calendar.components([.Day, .Month, .Year], fromDate: startDate)
		let endComponents = calendar.components([.Day, .Month, .Year], fromDate: endDate)
		if startComponents.year == endComponents.year
		{
			if startComponents.month == endComponents.month
			{
				if startComponents.day == endComponents.day
				{
					return formatDate(start)
				}
				else
				{
					return "\(startComponents.day) – " + formatDate(end)
				}
			}
			else
			{
					return shortFormatter.stringFromDate(startDate) + " – " + formatDate(end)
			}
		}
		
		return longFormatter.stringFromDate(startDate) + " – " + longFormatter.stringFromDate(endDate)
	}
	
	@IBAction func deleteAvailability(sender: AnyObject)
	{
		viewController.deleteAvailability(index)
	}	

	func createViewport(lat: Double, lon: Double) -> GMSCoordinateBounds
	{
		let neLocation = CLLocationCoordinate2DMake(lat + 0.001, lon + 0.001)
		let swLocation = CLLocationCoordinate2DMake(lat - 0.001, lon - 0.001)
		return GMSCoordinateBounds(coordinate: neLocation, coordinate: swLocation)
	}
}

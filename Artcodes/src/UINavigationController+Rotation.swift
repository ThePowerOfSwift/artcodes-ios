//
//  NavigationViewController+Rotation.swift
//  artcodes
//
//  Created by Kevin Glover on 1 Oct 2015.
//  Copyright © 2015 Horizon. All rights reserved.
//

import Foundation

extension UINavigationController
{
	open override var supportedInterfaceOrientations : UIInterfaceOrientationMask
	{
		if visibleViewController is UIAlertController
		{
			return super.supportedInterfaceOrientations
		}
		else if let mask = visibleViewController?.supportedInterfaceOrientations
		{
			return mask
		}
		return super.supportedInterfaceOrientations
	}
	
	open override var shouldAutorotate : Bool
	{
		return true
	}
}

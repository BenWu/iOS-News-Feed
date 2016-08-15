//
//  StoryViewController.swift
//  News Feed
//
//  Created by Ben Wu on 2016-08-13.
//  Copyright © 2016 Ben Wu. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class StoryViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var storyContent: UIWebView!
    
    var storyId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        if storyId != nil {
            Alamofire.request(.GET, "http://benwu.space:8000/story/" + storyId!).responseJSON { response in
                switch response.result {
                case .Success:
                    if let value = response.result.value {
                        let json = JSON(value)
                        print("Story content for \(json["id"]) loaded")
                        self.storyContent.loadHTMLString(json["body"].string!,
                            baseURL: nil)
                        self.storyContent.frame = CGRect(x: 10, y: 10, width: self.view.frame.size.width - 15, height: self.storyContent!.scrollView.contentSize.height - 30)
                    }
                case .Failure(let error):
                    print(error)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
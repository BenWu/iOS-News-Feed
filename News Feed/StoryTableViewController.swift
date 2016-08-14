//
//  StoryTableViewController.swift
//  News Feed
//
//  Created by Ben Wu on 2016-07-10.
//  Copyright © 2016 Ben Wu. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage


class StoryTableViewController: UITableViewController {

    // MARK: Properties
    
    var stories = [Story]()
    
    var loadingIndicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadingIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 40, 40))
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        loadingIndicator.center = self.view.center
        self.view.addSubview(loadingIndicator)
        
        if let savedStories = getLocalStories() {
            stories = savedStories
        } else {
            downloadStories()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stories.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "StoryCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! StoryCell

        let story = stories[indexPath.row]

        cell.title.text = story.title
        
        
        let url = NSURL(string: story.imageUrl)
        
        if url != nil {
            cell.thumbnail.af_setImageWithURL(url!)
        }
        
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "OpenStory" {
            let storyViewController = segue.destinationViewController as! StoryViewController
            
            if let selectedStoryCell = sender as? StoryCell {
                let index = tableView.indexPathForCell(selectedStoryCell)!
                let selectedStory = stories[index.row]
                storyViewController.storyId = selectedStory.id
                storyViewController.navigationItem.title = selectedStory.title
            }
        }
    }

    // MARK: Loading
    
    func showLoading() {
        loadingIndicator.startAnimating()
        loadingIndicator.backgroundColor = UIColor.clearColor()
    }
    
    func hideLoadingDelayed() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(),
            {
                self.hideLoading()
            })
    }
    
    func hideLoading() {
        print("hideloading")
        loadingIndicator.stopAnimating()
        loadingIndicator.hidesWhenStopped = true
    }
    
    func saveStories() {
        debugPrint("Saving stories")
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(stories, toFile: Story.ArchiveURL.path!)
        
        if !isSuccessfulSave {
            print("Failed to save meals...")
        }
    }
    
    func getLocalStories() -> [Story]? {
        debugPrint("Retrieving stories from local")
        return NSKeyedUnarchiver.unarchiveObjectWithFile(Story.ArchiveURL.path!) as? [Story]
    }
    
    @IBAction func refresh(sender: AnyObject) {
        debugPrint("Refreshing")
        downloadStories()
    }
    
    func downloadStories() {
        debugPrint("Downloading stories")
        showLoading()
        let request = NSMutableURLRequest(URL: NSURL(string: "http://benwu.space:8000/story")!)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            if error != nil {
                self.hideLoadingDelayed()
                debugPrint(error?.localizedDescription)
            } else {
                do {
                    let contentItems = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! NSArray
                    self.createStoriesFromJSON(contentItems)
                } catch {
                    debugPrint("Couldn't parse JSON")
                    self.hideLoadingDelayed()
                }
            }
        }
        task.resume()
    }
    
    func createStoriesFromJSON(jsonArr: NSArray) {
        if jsonArr.count > 0 {
            debugPrint("Parsing \(jsonArr.count) stories")
            
            stories.removeAll()
            
            for rawStory in jsonArr {
                
                let storyAsDictionary = rawStory as! NSDictionary
                
                let id = storyAsDictionary["id"] as! String
                let title = storyAsDictionary["title"] as! String
                let status = storyAsDictionary["status"] as! String
                let date = storyAsDictionary["date"] as! String
                let summary = storyAsDictionary["summary"] as! String
                let timestamp = storyAsDictionary["timestamp"] as! Int
                let imageUrl = storyAsDictionary["imageUrl"] as! String
                let categories = storyAsDictionary["categories"] as! [String]
                
                let newStory = Story(id: id, title: title, status: status, date: date, summary: summary, timestamp: timestamp,
                                     imageUrl: imageUrl, categories: categories)
                
                debugPrint("Saving story: \(newStory.id)")
                
                stories.append(newStory)
            }
            
            saveStories()
            
            self.tableView.reloadData()
            
        } else {
            debugPrint("No stories found")
        }
        hideLoadingDelayed()
    }

}

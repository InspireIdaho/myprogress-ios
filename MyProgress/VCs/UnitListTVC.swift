//  UnitListTVC.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import UIKit

class UnitListTVC: UITableViewController {
    
    var lessonUnits: [LessonUnit] = []
    var progressNodeGraph: ProgressNode?

    override func viewDidLoad() {
        super.viewDidLoad()

        lessonUnits = LessonNode.loadData()
        //print("loaded \(lessonUnits.count) units")
        
        if progressNodeGraph == nil {
            progressNodeGraph = ProgressNode.createProgressGraph(units: lessonUnits)
        }
        
        //print(progressNodeGraph!.totalLeafs)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return lessonUnits.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UnitProgressCell", for: indexPath)

        // Configure the cell...
        let unit = lessonUnits[indexPath.row]
        cell.textLabel?.text = unit.title
        if let unitProgress = ProgressNode.registry[unit.indexPath] {
            cell.detailTextLabel?.text = "\(unitProgress.completedLeafs) / \(unitProgress.totalLeafs)"
        }

        return cell
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowUnitLessons" {
            if let unitLessonListTVC = segue.destination as? UnitLessonListTVC {
                unitLessonListTVC.unit = sender as! LessonUnit
            }
        }
    }
 
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // get unit for row
        let unit = lessonUnits[indexPath.row]
        performSegue(withIdentifier: "ShowUnitLessons", sender: unit)
        
    }

}

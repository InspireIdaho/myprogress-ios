//  CourseUnitsListTVC.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import UIKit

class CourseUnitsListTVC: UITableViewController {
    
    var course: Course?
    //var progressNodeGraph: ProgressNode?
    
    @IBAction func saveProgress(_ sender: Any) {
        
        
        
        
        
//        // allow model methods to throw errors to UI
//        do {
//            let _ = try ProgressNode.saveCurrentProgress()
//
//        } catch {
//            // since in UI, can easily alert user
//            let alert = UIAlertController(title: "Save Error", message: "Progress not saved", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "Bummer", style: .default, handler: nil))
//            show(alert, sender: nil)
//        }
    }
    
    @IBAction func showSettings(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        course = Course.loadData()
        print("Finished loading Course outline")
        
        title = course?.title
        
        if let course = course {
            if ProgressNode.progressNodeGraph == nil {
                ProgressNode.progressNodeGraph = ProgressNode.createProgressGraph(course: course)
                print("Finished initializing _empty_ ProgressNodes for course")
            }
            
            do {
                let count = try ProgressNode.loadCurrentProgress()
                print("Loaded \(count) saved ProgressNodes")
            } catch {
                // since in UI, can easily alert user
                let alert = UIAlertController(title: "Load Error", message: "Prior Progress not loaded", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Bummer", style: .default, handler: nil))
                show(alert, sender: nil)
            }

        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let course = course {
            return course.units.count
        } else {
            return 0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UnitProgressCell", for: indexPath)

        // Configure the cell...
        if let course = course {
            
            let unit = course.units[indexPath.row]
            cell.textLabel?.text = unit.title
            if let unitProgress = ProgressNode.registry[unit.indexPath] {
                cell.detailTextLabel?.text = "\(unitProgress.completedLeafs) / \(unitProgress.totalLeafs)"
            }
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
                unitLessonListTVC.unit = sender as! CourseUnit
            }
        }
    }
 
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // get unit for row
        if let course = course {

        let unit = course.units[indexPath.row]
        performSegue(withIdentifier: "ShowUnitLessons", sender: unit)
        }
    }

}

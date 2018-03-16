//  LessonDetailTVC.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import UIKit

enum LessonSection: Int {
    case reading = 0
    case lab
    case review
    
    func title() -> String {
        let titles = ["Chapter Reading", "Lab Exercise", "Review Questions"]
        return titles[rawValue]
    }
}

class LessonDetailTVC: UITableViewController {

    var lesson: LessonNode!
    
    var progressComponents: [ProgressNode?] = [nil, nil, nil]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        for index in 0...2 {
            if let node = ProgressNode.registry[lesson.indexPath.appending(index)] {
                progressComponents[index] = node
            }
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch LessonSection(rawValue: section)! {
        case .reading:
            return 1
        case .lab:
            return lesson.hasLab ? 1 : 0
        case .review:
            return (lesson.reviewQuestions > 0 ) ? 1 : 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return LessonSection(rawValue: section)!.title()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LessonDetailCell", for: indexPath)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        // Configure the cell...
//        switch LessonSection(rawValue: indexPath.section)! {
//        case .reading:
            if let node = progressComponents[indexPath.section] {
                let completed = (node.completedOn != nil)
                cell.textLabel?.text = completed ? "Completed on: \(formatter.string(from: node.completedOn!))" : "Not Completed"
                cell.accessoryType = completed ? .checkmark : .none
            }
//            break
//        case .lab:
//            cell.textLabel?.text = "Not Completed"
//            break
//        case .review:
//            cell.textLabel?.text = "Not Completed"
//            break
//        }

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // toggle completed state for row in section
        if let node = progressComponents[indexPath.section] {
            let completed = (node.completedOn != nil)
            node.completedOn = completed ? nil : Date()
            tableView.reloadRows(at: [indexPath], with: .fade)
        }

    }


}

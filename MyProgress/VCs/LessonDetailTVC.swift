//  LessonDetailTVC.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import UIKit

enum LessonSection: Int {
    case reading = 0
    case lab
    case review
    
    func title() -> String {
        let titles = ["Reading", "Lab", "Review"]
        return titles[rawValue]
    }
}

class LessonDetailTVC: UITableViewController {
    
    struct EditDateContext {
        let lessonComponentName: String
        let node: ProgressNode
    }

    var lesson: LessonNode!
    
    var progressComponents: [ProgressNode?] = [nil, nil, nil]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = lesson.title
        
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
        
        if let node = progressComponents[indexPath.section] {
            cell.textLabel?.text = node.hasCompleted ? "Completed on: \(formatter.string(from: node.completedOn!))" : "Not Completed"
            cell.accessoryType = node.hasCompleted ? .detailDisclosureButton : .none
        }

        return cell
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "EditDate" {
            if let editDateVC = segue.destination as? EditDateVC {
                let context = sender as! EditDateContext
                editDateVC.targetNode = context.node
                editDateVC.title = "\(context.lessonComponentName) Completed On:"
                editDateVC.delegate = self
            }
        }

    }

    override func viewWillDisappear(_ animated: Bool) {
        if isMovingFromParent {
            
            // if node isDirty, save it and all nodes upstream, compute new % complete
            for node in progressComponents {
                if let node = node, node.hasChanges {
                    print("about to save node: \(node.debugDescription)")
                    
                   // mark node
                    // first just save it
                    //ServerProxy.saveNode(node: node)
                    node.syncToServer()
                }
            }
        }
        super.viewWillDisappear(animated)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // toggle completed state for row in section
        if let node = progressComponents[indexPath.section] {
            // toggle completion
            node.completedOn = node.hasCompleted ? nil : Date()
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if let node = progressComponents[indexPath.section] {
            let title = LessonSection(rawValue: indexPath.section)!.title()
            let context = EditDateContext(lessonComponentName: title, node: node)
            performSegue(withIdentifier: "EditDate", sender: context)
        }

    }


}

extension LessonDetailTVC : EditDateVCDelegate {
    
    func editDateVCDidCancel() {
        //do nothing, dismiss
        //dismiss(animated: true, completion: nil)
        navigationController?.popViewController(animated: true)
    }
    
    func editDateVCDidFinishWith(newdate: Date, for node: ProgressNode) {
        node.completedOn = newdate
        tableView.reloadData()
        navigationController?.popViewController(animated: true)
    }
   
}

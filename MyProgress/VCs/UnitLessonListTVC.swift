//  LessonListTVC.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import UIKit


class UnitLessonListTVC: UITableViewController {

    var unit: CourseUnit!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = unit.title
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
        return unit.lessons.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LessonProgressCell", for: indexPath)

        // Configure the cell...
        let lesson = unit.lessons[indexPath.row]
        cell.textLabel?.text = "\(lesson.indexPath.dotText()) \(lesson.title)"

        if let lessonProgress = ProgressNode.registry[lesson.indexPath] {
            cell.detailTextLabel?.text = "\(lessonProgress.completedLeafs) / \(lessonProgress.totalLeafs)"
        }


        return cell
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "EditLesson" {
            if let lessonDetailTVC = segue.destination as? LessonDetailTVC {
                lessonDetailTVC.lesson = sender as! LessonNode
            }
        }

    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // get lesson for row
        let lesson = unit.lessons[indexPath.row]
        performSegue(withIdentifier: "EditLesson", sender: lesson)
    }


}

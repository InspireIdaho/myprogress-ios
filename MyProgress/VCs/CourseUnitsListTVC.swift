//  CourseUnitsListTVC.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import UIKit
import Alamofire

class CourseUnitsListTVC: UITableViewController {
    
    /// the course to display
    var course: Course?
    
    
    @IBAction func showSettings(_ sender: Any) {
        performSegue(withIdentifier: "ShowSettings", sender: self)
    }
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        course = Course.loadData()
        print("Finished loading Course outline")
        
        title = course?.title
        
        if let course = course {
            ProgressNode.createProgressGraph(course: course)

            if User.principle != nil {
                DataBroker.isAuthenticated(
                    success: {
                        DataBroker.getAllProgressNodes {
                            //print("finished fetch, back in UI")
                            self.tableView.reloadData()
                        }
                },
                    failure: {
                        self.alertAuthExpired()
                }
                )
            } else {
                self.performSegue(withIdentifier: "ShowSettings", sender: self)
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // in future, check with DataBroker whether to enable "sync" button
        // for now, disable
        //syncBarButton.isEnabled = false
        if let course = course {
            // safe to call mult times, will only re-build if nil
            ProgressNode.createProgressGraph(course: course)
        }
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if (User.principle == nil) {
            let alert = UIAlertController(title: "Data in Jeopardy!", message: "Warning: without registering/authenticating a user at remote web service, all progress data is stored in memory only, and will be GONE next time app is launched.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Danger is my middle name", style: .default) { alert in
                
            })
            if (navigationController?.topViewController == self) {
                self.present(alert, animated: true)
            }
        }

    }
    
    // MARK: - Navigation
    
    /// helper
    func alertAuthExpired() {
        let alert = UIAlertController(title: "Login Expired!", message: "Warning: auth token has expired. Cannot retrieve existing or save new progress data at remote web service until re-login.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Go to User Settings", style: .default) { alert in
            self.performSegue(withIdentifier: "ShowSettings", sender: self)
        })

        alert.addAction(UIAlertAction(title: "Danger is my middle name", style: .cancel) { alert in
            
        })
        if (navigationController?.topViewController == self) {
            self.present(alert, animated: true)
        }

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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // get unit for row
        if let course = course {
            
            let unit = course.units[indexPath.row]
            performSegue(withIdentifier: "ShowUnitLessons", sender: unit)
        }
    }

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
 
    

}

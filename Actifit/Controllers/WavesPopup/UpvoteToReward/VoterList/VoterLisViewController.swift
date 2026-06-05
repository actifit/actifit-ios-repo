//
//  VoterLisViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 22/04/2024.
//

import UIKit

class VoterLisViewController: UIViewController {
  @IBOutlet weak var tableView: UITableView!
  var votes: [ActiveVote] = []
    override func viewDidLoad() {
        super.viewDidLoad()
      setTableView()
        // Do any additional setup after loading the view.
    }

  private func setTableView() {
    tableView.register(UINib(nibName: "VotersCell", bundle: nil), forCellReuseIdentifier: "VotersCell")
  }

  static func create(voters: [ActiveVote]) -> VoterLisViewController {
    let vc = UIStoryboard(name: "WavesPopup", bundle: nil).instantiateViewController(withIdentifier: "VoterLisViewController") as! VoterLisViewController
    vc.votes = voters
    vc.modalPresentationStyle = .overFullScreen
    return vc
  }

  @IBAction func closeBtnTapped(_ sender: Any) {
    dismiss(animated: true)
  }

}

extension VoterLisViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "VotersCell") as? VotersCell
    cell?.vote = votes[indexPath.row]
    return cell!

  }
  

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return votes.count

  }

}

//
//  PollDisplayViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 28/09/2023.
//

import UIKit
import Combine
class PollDisplayViewController: UIViewController {
    var viewModel: PollDisplayViewModel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var backgroundLayerView: UIView!
    @IBOutlet weak var voteBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!
    private var cancellables = Set<AnyCancellable>()
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setBinding()
        // Do any additional setup after loading the view.
    }
    
    
    static func create(pollViewModel: PollDisplayViewModel) -> PollDisplayViewController {
        let vc = UIStoryboard(name: "PollDisplay", bundle: nil).instantiateViewController(withIdentifier: "PollDisplayViewController") as! PollDisplayViewController
        vc.viewModel = pollViewModel
        return vc
    }
    
    @IBAction func voteBtnTapped(_ sender: Any) {
        viewModel.castVoteAPI()
    }
    
    
    @IBAction func closeBtnTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    private func setUI() {
        backgroundLayerView.layer.cornerRadius = 10
        backgroundLayerView.clipsToBounds = true
        closeBtn.layer.cornerRadius = 5
        closeBtn.clipsToBounds = true
        voteBtn.layer.cornerRadius = 5
        voteBtn.clipsToBounds = true
        tableView.register(UINib(nibName: "PollTextCell", bundle: nil), forCellReuseIdentifier: "PollTextCell")
        tableView.register(UINib(nibName: "PollChoiceCell", bundle: nil), forCellReuseIdentifier: "PollChoiceCell")
        tableView.separatorStyle = .none
        
    }
    
    private func setBinding() {
        viewModel.refreshPublisher.sink { refresh in
            self.tableView.reloadData()
        }.store(in: &cancellables)
        
        viewModel.didVoteSuccessfullyPublisher.sink { voteSuccess in
            if voteSuccess {
                self.showAlertWithOkCompletion(title: "", message: "Successfully voted!") { finished in
                    self.dismiss(animated: true)
                }
            } else {
                self.showAlertWith(title: "", message: "There was an error casting your vote")
            }
        }.store(in: &cancellables)
    }
    
}

extension PollDisplayViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let pollTextCell = tableView.dequeueReusableCell(withIdentifier: "PollTextCell") as? PollTextCell
        let pollChoiceCell = tableView.dequeueReusableCell(withIdentifier: "PollChoiceCell") as? PollChoiceCell
        pollChoiceCell?.selectionStyle = .none
        pollTextCell?.selectionStyle = .none
        if indexPath.row == 0 {
            pollTextCell?.textString = "Quick Poll"
            return pollTextCell!
        } else if indexPath.row == 1 {
            pollTextCell?.textString =  viewModel.surveyModel.title
            return pollTextCell!
        } else if indexPath.row == 2 {
            pollTextCell?.textString = viewModel.getPollParticipationText()
            pollTextCell?.titleLabel.textColor = .gray
            return pollTextCell!
        }
        else {
            pollChoiceCell?.pollChoice = viewModel.getPollModelByIndex(index: indexPath.row)
            pollChoiceCell?.changeSelection = { [weak self] newSelectionState in
                self?.viewModel.updateChoiceSelection(index: indexPath.row, newStatus: newSelectionState)
            }
            return pollChoiceCell!
        }
    }


func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.numberOfRows
}

func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
}


}

////  FlashcardsTableViewController.swift//  Group10FinalProject////  Created by user264785 on 11/22/24.//import UIKitclass FlashcardsTableViewController: UITableViewController {    var flashcards: [Flashcard] = []    override func viewDidLoad() {        super.viewDidLoad()        self.title = "Flashcards"        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FlashcardCell")        self.tableView.separatorStyle = .singleLine    }    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {        return flashcards.count    }    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        let cell = tableView.dequeueReusableCell(withIdentifier: "FlashcardCell", for: indexPath)        let flashcard = flashcards[indexPath.row]        cell.textLabel?.text = """        Term: \(flashcard.term)        Explanation: \(flashcard.explanation)        """        cell.textLabel?.numberOfLines = 0        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)        cell.selectionStyle = .none         return cell    }}
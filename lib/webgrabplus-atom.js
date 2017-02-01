'use babel';

import WebgrabplusatomView from './webgrabplus-atom-view';
import { CompositeDisposable } from 'atom';
var path = require('path');

export default {

  webgrabplusatomView: null,
  modalPanel: null,
  subscriptions: null,

  activate(state) {
    this.webgrabplusatomView = new WebgrabplusatomView(state.webgrabplusatomViewState);
    this.modalPanel = atom.workspace.addModalPanel({
      item: this.webgrabplusatomView.getElement(),
      visible: false
    });

    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable();

    // Register command
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'webgrabplus:siteinicleanup': () => this.siteinicleanup()
    }));

    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'webgrabplus:confingadjust': () => this.confingadjust()
    }));
  },

  deactivate() {
    this.modalPanel.destroy();
    this.subscriptions.dispose();
    this.webgrabplusatomView.destroy();
  },

  serialize() {
    return {
      webgrabplusatomViewState: this.webgrabplusatomView.serialize()
    };
  },

  siteinicleanup() {
    //@todo
    //return;
    console.log('webgrabplus-atom siteinicleanup!');
    let editor
    if (editor = atom.workspace.getActiveTextEditor()) {
      let selection = editor.getSelectedText()
      if("" == selection){
        selection = editor.getText()
        let reversed = selection.split('').reverse().join('')
        editor.setText(reversed)
      }
      else{
        let reversed = selection.split('').reverse().join('')
        editor.insertText(reversed)
      }
    }
  },

  confingadjust() {
    console.log('webgrabplus-atom confingadjust!');
    let editor
    if (editor = atom.workspace.getActiveTextEditor()) {
      let selection = editor.getBuffer()
      selection.scan(/<filename>(.*?)<\/filename>/, (scanresult) =>
        { this._confingadjust_replace(editor, scanresult)})
    }
  },


  _confingadjust_replace(editor, scanresult){
    // get the original filename
    let filename = path.basename(scanresult.match[1]);
    // get the new folder name
    let foldername = path.dirname(editor.getPath());
    // join them together
    let newValue = path.join(foldername,filename);
    // replace the filename in the file
    scanresult.replace("<filename>"+ newValue +"</filename>")
  }

};

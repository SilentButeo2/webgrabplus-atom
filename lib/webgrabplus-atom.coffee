WebgrabplusAtomView = require './webgrabplus-atom-view'
{CompositeDisposable} = require 'atom'
{TextBuffer} = require 'atom'


{ install } = require 'atom-package-deps'
{ spawnSync } = require 'child_process'

os = require 'os'

# Package settings
meta = require '../package.json'

module.exports = WebgrabplusAtom =
  webgrabplusAtomView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @webgrabplusAtomView = new WebgrabplusAtomView(state.webgrabplusAtomViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @webgrabplusAtomView.getElement(), visible: false)

    if  !atom.inSpecMode()
        install meta.name

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'webgrabplus-atom:siteinicleanup': => @siteinicleanup()
    @subscriptions.add atom.commands.add 'atom-workspace', 'webgrabplus-atom:confingadjust': => @confingadjust()

    console.log 'WebGrab+Plus path = ' + atom.config.get('webgrabplus-atom.path')

    console.log 'webgrabplus-atom activated'

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @webgrabplusAtomView.destroy()

  serialize: ->
    webgrabplusAtomViewState: @webgrabplusAtomView.serialize()

  siteinicleanup: ->
    console.log 'Webgrabplusatom - siteinicleanup'
    if editor = atom.workspace.getActiveTextEditor()
      txtBufOld = new TextBuffer(editor.getText())
      txtBufNew = new TextBuffer()
      #allTxt.deleteRow(0)
      #editor.setText(allTxt.getText())
      nLineCount = txtBufOld.getLineCount();
      console.log 'nLineCount ' + nLineCount;
      for row in txtBufOld.getLines()
        do ->
          #console.log 'row: ' + row
          # remove debug words inside command brackets (if it only contains debug)
          re =
            ///
            \{\s*
            (single|multi|addstart|addend|replace|substring|remove|cleanup|calculate|clear|url|select|sort|regex)
            \s*\(\s*debug\s*\)
            ///i
          row = row.replace(re,"{$1");

          # remove all the debug entries (with other commands inside the brackets
          # debug is the first value in the brackets
          re =
            ///
            \{\s*
            (single|multi|addstart|addend|replace|substring|remove|cleanup|calculate|clear|url|select|sort|regex)
            \s*\(\s*debug\W([^)]*)\)
            ///i
          row = row.replace(re,"{$1($2)");

          # debug is the midle value in the brackets
          re =
            ///
            \{\s*
            (single|multi|addstart|addend|replace|substring|remove|cleanup|calculate|clear|url|select|sort|regex)
            \s*\(([^)]*)\Wdebug\W([^)]*)\)
            ///i
          row = row.replace(re,"{$1($2$3)");

          # debug is the last value in the brackets
          re =
            ///
            \{\s*
            (single|multi|addstart|addend|replace|substring|remove|cleanup|calculate|clear|url|select|sort|regex)
            \s*\(([^)]*)\Wdebug\s*\)
            ///i
          row = row.replace(re,"{$1($2)");

          # remove empty command brackets
          re =
            ///
            \{\s*
            (single|multi|addstart|addend|replace|substring|remove|cleanup|calculate|clear|url|select|sort|regex)
            \s*\(\s*\)
            ///i
          row = row.replace(re,"{$1");

          # remove leading and trailing spaces at the beginning of the brackets
          re =
            ///
            \{\s*
            (single|multi|addstart|addend|replace|substring|remove|cleanup|calculate|clear|url|select|sort|regex)
            \s*\(\s*([^\)]*?)\s*\)
            ///i
          row = row.replace(re,"{$1($2)");

          # remove leading and trailing spaces
          row = row.replace(///^\s*(.*?)\s*$///i,"$1");

          txtBufNew.append(row + '\n')
      editor.setText(txtBufNew.getText())
      console.log 'done'

  run: ->
    console.log 'Webgrabplusatom - run!'

  confingadjust: ->
    console.log 'Webgrabplusatom - confingadjust'

  buildprovider: ->
    console.log 'calling the WebGrabPlusProvider'
    class WebGrabPlusProvider
      constructor: (@cwd) ->

      getNiceName: ->
        console.log 'calling the WebGrabPlusProvider.getNiceName'
        'WebGrab+Plus'

      isEligible: ->
        console.log 'calling the WebGrabPlusProvider.isEligible'
        true

      settings: ->
        console.log 'calling the WebGrabPlusProvider.settings'
        [
          {
            name: 'WebGrab+Plus',
            exec: atom.config.get('webgrabplus-atom.path'),
            args: [ '{FILE_ACTIVE_PATH}' ],
            cwd: '{FILE_ACTIVE_PATH}',
            sh: false,
            keymap: 'alt-w',
            atomCommandName: 'webgrabplus-atom:run'
            #errorMatch: ['(?<file>([^:]+)):(?<line>\\d+):(?<col>\\d+): (?<message>.+)']
          }
        ]

###



  siteinicleanup() {
    console.log('webgrabplus-atom siteinicleanup!');
    let editor
    if (editor = atom.workspace.getActiveTextEditor()) {
      let selection = editor.getSelectedText()
      //if("" == selection){
        //selection = editor.getText()
        //editor.setText(this._cleanup(editor,selection))
      //}
      //else{
        //this._cleanup(editor,selection)
        this._cleanup_txbuf(editor)
        //editor.insertText()
      //}
    }
  },
  _cleanup_txbuf(editor)
  {
    let txtBuf = new
    editor.getText()

  };

  _cleanup(editor,selection)
  {
    let nLineCount = editor.getLineCount();
    let i;
    let content;
    console.log("nLineCount " + nLineCount);
    for(i=0; i<nLineCount; i++)
    {
      console.log("row " + i);
      row = editor.lineTextForBufferRow(i);
      // remove debug words inside command brackets (if it only contains debug)
      row = row.replace(/(single)\s*\(\s*debug\s*\)/i,"$1");

      // remove all the debug entries (with other commands inside the brackets
      row = row.replace(/(single)\s*\(\s*debug\W([^)]*)\)/, "$1($2)");         // debug is the first value in the brackets
      row = row.replace(/(single)\s*\(([^)]*)\Wdebug\W([^)]*)\)/, "$1($2$3)"); // debug is the midle value in the brackets
      row = row.replace(/(single)\s*\(([^)]*)\Wdebug\s*\)/, "$1($2)");			    // debug is the last value in the brackets

      // remove empty command brackets
      row = row.replace(/(single)\s*\(\s*\)/,"$1");

      // remove leading and trailing spaces at the beginning of the brackets
      row = row.replace(/(single)\s* /, "$1(");
      //selection = selection.replace(/(single)\s*\(\s*([^\)]*?)\s*\)/, "$1($2)")

      //content += row;
      //editor.setTextInBufferRange([[i,0],[i,0]],  row)
      editor.deleteRow(i);
    }

    return;
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



###

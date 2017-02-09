WebgrabplusAtomView = require './webgrabplus-atom-view'
{ CompositeDisposable } = require 'atom'
{ TextBuffer } = require 'atom'
{ File } = require 'atom'
{ install } = require 'atom-package-deps'
{ execSync } = require 'child_process'

os = require 'os'

# Package settings
meta = require '../package.json'

module.exports = WebgrabplusAtom =
  webgrabplusAtomView: null
  modalPanel: null
  subscriptions: null
  buildPathwg: false
  buildPathmono: false
  bMonoUsed: false
  pathwg: ''
  pathmono: ''

  activate: (state) ->
    @webgrabplusAtomView = new WebgrabplusAtomView(state.webgrabplusAtomViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @webgrabplusAtomView.getElement(), visible: false)

    if  !atom.inSpecMode()
        install meta.name

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register our commands
    @subscriptions.add atom.commands.add 'atom-text-editor', 'webgrabplus-atom:tidy-siteini': => @tidy_siteini()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'webgrabplus-atom:confingadjust': => @confingadjust()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'webgrabplus-atom:selectPathWg': => @selectPathWg()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'webgrabplus-atom:selectPathMono': => @selectPathMono()
    #@subscriptions.add atom.commands.add 'atom-text-editor', 'webgrabplus-atom:run': => @run()

    console.log 'path WebGrab+Plus: ' + atom.config.get('webgrabplus-atom.path-wg')
    console.log 'path Mono        : ' + atom.config.get('webgrabplus-atom.path-mono')

    console.log 'webgrabplus-atom activated'

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @webgrabplusAtomView.destroy()

  serialize: ->
    webgrabplusAtomViewState: @webgrabplusAtomView.serialize()

  run: ->
    console.log 'os.platform() = ' + os.platform()
    if not @buildPathwg
      atom.notifications.addError('WebGrab+Plus.exe not found', {detail: 'Check the package settings.\nYou can set it with\nPackage > WebGrab+Plus > Set WebGrab+Plus.exe'})
    else if 'win32' is not os.platform() and not @buildPathmono
      atom.notifications.addError('mono not found', {detail: 'Check the package settings.\nYou can set it with\nPackage > WebGrab+Plus > Set mono'})
    console.log 'Webgrabplusatom - run!'

  confingadjust: ->
    console.log 'Webgrabplusatom - confingadjust'

  selectPathWg: ->
    { remote } = require 'electron'
    files = remote.dialog.showOpenDialog(remote.getCurrentWindow(), {properties:['openFile'], filters:[{name: 'Executable', extensions: ['exe']}]})
    if files and files.length
      atom.config.set('webgrabplus-atom.path-wg', files[0])

    if atom.config.get('webgrabplus-atom.path-wg') isnt @pathwg
      notification = atom.notifications.addWarning('Path changed, you need to restart Atom',
       {
         dismissable: true,
         detail: 'The path to WebGrab+Plus.exe has been changed. A restart of Atom is needed, for the changes to take effect',
         buttons: [text: 'restart', onDidClick: ->
           atom.restartApplication()
           notification.dismiss()
         ]
        })

  selectPathMono: ->
    { remote } = require 'electron'
    files = remote.dialog.showOpenDialog(remote.getCurrentWindow(), {properties:['openFile']})
    if files and files.length
      atom.config.set('webgrabplus-atom.path-mono', files[0])

    if atom.config.get('webgrabplus-atom.path-mono') isnt @pathmono
      notification = atom.notifications.addWarning('Path changed, you need to restart Atom',
       {
         dismissable: true,
         detail: 'The path to mono has been changed. A restart of Atom is needed, for the changes to take effect',
         buttons: [text: 'restart', onDidClick: ->
           atom.restartApplication()
           notification.dismiss()
         ]
        })

  buildprovider: ->
    # save the paths that are used by the build package.
    # this is later needed to see if the path(s) have changed
    @pathwg = atom.config.get('webgrabplus-atom.path-wg')
    @pathmono = atom.config.get('webgrabplus-atom.path-mono')

    fwg = new File(@pathwg)
    if fwg.existsSync()
      @buildPathwg = true

    if 'win32' is not os.platform()
      console.log 'Cheking if mono is found'
      if not (@pathmono?.length)
         @bMonoUsed = true
    else
      @bMonoUsed = false

    if not @bMonoUsed
      console.log 'Mono will not be used'
    else
      if not (@pathmono?.length)
        @pathmono = 'mono'
        atom.config.set('webgrabplus-atom.path-mono', @pathmono)
      try
        stdout = execSync @pathmono + ' --version'
        @buildPathmono = true
        console.log 'Mono OK'
      catch error
        console.log 'Mono NOK'

    # return no build provider, if there was an issue with the env.
    if not (@buildPathwg and (not @bMonoUsed or @buildPathmono))
      return null

    class WebGrabPlusProvider
      constructor: (@cwd) ->

      getNiceName: ->
        'WebGrab+Plus'

      isEligible: ->
        return true

      settings: ->
        console.log 'calling the WebGrabPlusProvider.settings'
        mono = atom.config.get('webgrabplus-atom.path-mono')
        wg = atom.config.get('webgrabplus-atom.path-wg')

        if not (mono?.length)
            return [
              {
                name: 'WebGrab+Plus',
                exec: wg,
                args: [ '{FILE_ACTIVE_PATH}' ],
                cwd: '{FILE_ACTIVE_PATH}',
                sh: false,
              }
            ]
        else
          return [
            {
              name: 'WebGrab+Plus',
              exec: mono
              args: [ wg, '{FILE_ACTIVE_PATH}' ]
              cwd: '{FILE_ACTIVE_PATH}',
              sh: false,
            }
          ]

  tidy_siteini: ->
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

{ko, Immutable: {Map, List}} = require "carma/vendor"
{backgrounds} = require "./precompiled"
{store} = require "carma/neoComponents/store"
{CaseHistoryList} = require "carma/neoComponents/store/diagTree/show/models"
{} = require "carma/neoComponents/store/diagTree/show/actions"

require "./styles.less"

yesNoRegs = [/^да/i, /^нет/i]


# This component isn't supposed to be mounted at top-level,
# it"s supposed to always be wrapped by diag-tree-show.
class DiagTreeShowInsideViewModel
  # caseModel: see store/diagTree/show/models
  constructor: ({@caseModel}) ->
    @subscriptions = [] # Mutable

    @originalHistory = ko.pureComputed => @caseModel().get "history"

    @history = ko.pureComputed =>
      @originalHistory().onlyNotDeprecated().toArray()

    @showDeprecated = ko.observable null
    @slideId = ko.observable null
    @hoverId = ko.observable null

    @slideHeader = ko.observable "testing slide header"

    @subscriptions.push @originalHistory.subscribeWithOld (newVal, oldVal) =>
      if oldVal.size is 0 and newVal.size > 0
        @slideId newVal.last().get "id"

  dispose: =>
    do x.dispose for x in @subscriptions

  prevHistory: (id) => @originalHistory().getPreviousById id
  hasPrevHistory: (id) => @prevHistory(id).length > 0
  showDeprecatedAnswers: (model) => @showDeprecated model.get "id"
  hideDeprecatedAnswers: => @showDeprecated null
  onHistoryClick: (model) => @slideId model.get "id"
  onHistoryMouseEnter: (model) => @hoverId model.get "id"
  onHistoryMouseLeave: (model) => @hoverId null if @hoverId() is model.get "id"


module.exports =
  componentName: "diag-tree-show-inside"

  component:
    template:  require "./template.pug"
    viewModel: DiagTreeShowInsideViewModel

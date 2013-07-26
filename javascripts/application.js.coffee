#= require vendor/zepto
#= require vendor/underscore
#= require vendor/backbone
$ ->
  source = new EventSource '/subscribe'
  window.flatware = new Flatware
  source.onmessage = (e)->
    [event, data] = JSON.parse e.data
    flatware.trigger event, data

  source.onerror = (e)-> console.log e.type
  source.onopen  = (e)-> console.log e.type

  new View.Flatware model: flatware

class Flatware extends Backbone.Model
  initialize: ->
    @jobs    = new Backbone.Collection model: Job
    @workers = new Backbone.Collection
    @on 'all', (event)=> console.log arguments

    @on 'jobs', (jobs)=> @jobs.set jobs
    @on 'started', (work)=>
      {worker, job} = work
      worker = @workers.add(id: worker).get(worker)
      job = @jobs.add(id: job).get(job)
      job.set(workerId: worker)
      worker.set(job: job)

    @on 'progress', (progress)=>
      {status, worker} = progress
      @workers.get(worker).set(status: status)

    # @on 'all', -> console.log arguments


View = {}

class Job extends Backbone.Model
  initialize: ->


class View.Job extends Backbone.View
  tagName: 'li'
  initialize: ->
    @listenTo @model, 'change', @render
    @listenTo @model, 'change:workerId', @remove
  render: ->
    @$el.html @model.id
    this

class View.Worker extends Backbone.View
  tagName: 'li'
  initialize: ->
    @listenTo @model, 'change', @render
    @listenTo @model, 'change:job', @render
  render: ->
    @$el.html "#{@model.id}<br>#{@model.get('job')?.id}"
    this

class View.Flatware extends Backbone.View
  initialize: ->
    @listenTo @model.jobs, 'add', (job)->
      new View.Job(model: job).render().$el.appendTo '#waiting'

    @listenTo @model.workers, 'add', (job)->
      new View.Worker(model: job).render().$el.appendTo '#workers'

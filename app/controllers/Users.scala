package controllers

import play.api._
import play.api.i18n.Messages
import play.api.mvc._
import play.api.data.Forms._
import play.api.data._
import play.api.Play.current
import play.api.libs._
import play.api.cache._
import play.api.libs.json._

import models.User
import play.api.libs.concurrent.Execution.Implicits._

object Users extends Controller with Secured {
  def login = TODO

  def logout = TODO

  def signup = TODO
}
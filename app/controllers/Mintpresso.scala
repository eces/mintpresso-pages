package controllers

import play.api._
import play.api.Play.current
import play.api.libs.ws._
import play.api.libs.ws.WS._

class Mintpresso(val url: String) {
  def withConnection[A](block: WSRequestHolder => A)(implicit app: Application): A = {
    app.configuration.getString("mintpresso.server") map { baseUrl =>
      app.configuration.getString("mintpresso.default") map { key =>
        block( WS.url(baseUrl + url).withQueryString( "apikey" -> key ) )
      } getOrElse {
        throw new Exception("mintpresso.default is missing.")
      }
    } getOrElse {
      throw new Exception("mintpresso.server is missing.")
    }
  }
  def get = {
    this.withConnection { conn =>
      conn.get()
    }
  }
}

object Mintpresso {
  def apply(url: String) = {
    new Mintpresso(url)
  }
}
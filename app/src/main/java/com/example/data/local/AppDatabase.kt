package com.example.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.example.data.model.Student

val MIGRATION_1_2 = object : Migration(1, 2) {
  override fun migrate(db: SupportSQLiteDatabase) {
    db.execSQL("ALTER TABLE students ADD COLUMN currentMonthStatus TEXT NOT NULL DEFAULT 'DUE'")
    db.execSQL("ALTER TABLE students ADD COLUMN paymentHistory TEXT NOT NULL DEFAULT ''")
  }
}

@Database(entities = [Student::class], version = 2, exportSchema = false)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {

  abstract fun studentDao(): StudentDao

  companion object {
    @Volatile
    private var INSTANCE: AppDatabase? = null

    fun getDatabase(context: Context): AppDatabase {
      return INSTANCE ?: synchronized(this) {
        val instance = Room.databaseBuilder(
          context.applicationContext,
          AppDatabase::class.java,
          "tuition_students_ledger.db"
        )
          .addMigrations(MIGRATION_1_2)
          .fallbackToDestructiveMigration(true)
          .build()
        INSTANCE = instance
        instance
      }
    }
  }
}

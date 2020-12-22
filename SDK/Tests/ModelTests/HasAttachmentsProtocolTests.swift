//  Copyright (c) 2020 D4L data4life gGmbH
//  All rights reserved.
//  
//  D4L owns all legal rights, title and interest in and to the Software Development Kit ("SDK"),
//  including any intellectual property rights that subsist in the SDK.
//  
//  The SDK and its documentation may be accessed and used for viewing/review purposes only.
//  Any usage of the SDK for other purposes, including usage for the development of
//  applications/third-party applications shall require the conclusion of a license agreement
//  between you and D4L.
//  
//  If you are interested in licensing the SDK for your own applications/third-party
//  applications and/or if you’d like to contribute to the development of the SDK, please
//  contact D4L by email to help@data4life.care.

import XCTest
@testable import Data4LifeSDK
import Data4LifeFHIR

// swiftlint:disable cyclomatic_complexity
extension AttachmentSchema: Equatable {
    public static func == (lhs: AttachmentSchema, rhs: AttachmentSchema) -> Bool {
        switch (lhs, rhs) {
        case (.single, .single):
            return true
        case (.list, .list):
            return true
        case (.observation, .observation):
            return true
        case (.questionnaire, .questionnaire):
            return true
        case (.questionnaireItem, .questionnaireItem):
            return true
        case (.questionnaireResponse, .questionnaireResponse):
            return true
        case (.questionnaireResponseItem, .questionnaireResponseItem):
            return true
        case (.questionnaireResponseItemAnswer, .questionnaireResponseItemAnswer):
            return true
        case (.questionnaireR4, .questionnaireR4):
            return true
        case (.questionnaireItemR4, .questionnaireItemR4):
            return true
        case (.questionnaireResponseR4, .questionnaireResponseR4):
            return true
        case (.questionnaireResponseItemR4, .questionnaireResponseItemR4):
            return true
        case (.questionnaireResponseItemAnswerR4, .questionnaireResponseItemAnswerR4):
            return true
        case (.questionnaireItemInitialR4, .questionnaireItemInitialR4):
            return true
        default:
            return false
        }
    }
}

// swiftlint:disable identifier_name
class HasAttachmentsProtocolTests: XCTestCase {

    func testDocumentReferencHasAttachments() throws {
        let documentReference = DocumentReference()
        XCTAssertNil(documentReference.allAttachments)
        let expectedIdentifier = UUID().uuidString
        let expectedAttachment = FhirFactory.createStu3AttachmentElement()

        documentReference.content = [DocumentReferenceContent(attachment: expectedAttachment)]
        documentReference.addAdditionalId(expectedIdentifier)

        XCTAssertEqual(expectedAttachment, documentReference.allAttachments?.first as? Attachment, "Result differs from expected attachments")
        XCTAssertTrue((documentReference as CustomIdentifierProtocol).customIdentifiers?.first?.valueString?.contains(expectedIdentifier) ?? false, "Result differs from expected identifiers")

        //AttachmentSchema Test
        XCTAssertEqual(documentReference.schema, AttachmentSchema.list([expectedAttachment]), "The attachment schema is wrong")

        let expectedAttachmentWithId = expectedAttachment.copyWithId(UUID().uuidString)
        let notExpectedAttachment = FhirFactory.createStu3SampleImageAttachment()

        var filledAttachments: [AttachmentType] = [expectedAttachmentWithId, notExpectedAttachment]
        let schemaResult = try documentReference.makeFilledSchema(byMatchingTo: &filledAttachments)

        XCTAssertEqual(schemaResult, AttachmentSchema.list([expectedAttachmentWithId]), "The returned schema is wrong")
        documentReference.content = nil
        let exampleSchema = AttachmentSchema.list([expectedAttachment])
        documentReference.updateAttachments(from: exampleSchema)
        XCTAssertEqual(documentReference.allAttachments as? [Attachment], [expectedAttachment], "After updating the attachments the expected attachments are not the one expected")
    }

    func testDiagnosticReportHasAttachments() throws {
        let report = DiagnosticReport()
        XCTAssertNil(report.allAttachments)
        let expectedIdentifier = UUID().uuidString
        let expectedAttachment = FhirFactory.createStu3AttachmentElement()

        report.presentedForm = [expectedAttachment]
        report.addAdditionalId(expectedIdentifier)

        XCTAssertEqual(expectedAttachment, report.allAttachments?.first as? Attachment)
        XCTAssertTrue((report as CustomIdentifierProtocol).customIdentifiers?.first?.valueString?.contains(expectedIdentifier) ?? false)

        //AttachmentSchema Test
        XCTAssertEqual(report.schema, AttachmentSchema.list([expectedAttachment]), "The attachment schema is wrong")

        let expectedAttachmentWithId = expectedAttachment.copyWithId(UUID().uuidString)
        let notExpectedAttachment = FhirFactory.createStu3SampleImageAttachment()

        var filledAttachments: [AttachmentType] = [expectedAttachmentWithId, notExpectedAttachment]
        let schemaResult = try report.makeFilledSchema(byMatchingTo:
                                                        &filledAttachments
        )

        XCTAssertEqual(schemaResult, AttachmentSchema.list([expectedAttachmentWithId]), "The returned schema is wrong")
        report.presentedForm = nil
        let exampleSchema = AttachmentSchema.list([expectedAttachment])
        report.updateAttachments(from: exampleSchema)
        XCTAssertEqual(report.allAttachments as? [Attachment], [expectedAttachment], "After updating the attachments the expected attachments are not the one expected")
    }

    func testMedicationHasAttachments() throws {
        let medication = Medication()
        XCTAssertNil(medication.allAttachments)

        let expectedAttachment = FhirFactory.createStu3ImageAttachmentElement()
        medication.image = [expectedAttachment]

        XCTAssertEqual(expectedAttachment, medication.allAttachments?.first as? Attachment)

        //AttachmentSchema Test
        XCTAssertEqual(medication.schema, AttachmentSchema.list([expectedAttachment]), "The attachment schema is wrong")

        let expectedAttachmentWithId = expectedAttachment.copyWithId(UUID().uuidString)
        let notExpectedAttachment = FhirFactory.createStu3SampleImageAttachment()

        var filledAttachments: [AttachmentType] = [expectedAttachmentWithId, notExpectedAttachment]
        let schemaResult = try medication.makeFilledSchema(byMatchingTo: &filledAttachments)

        XCTAssertEqual(schemaResult, AttachmentSchema.list([expectedAttachmentWithId]), "The returned schema is wrong")
        medication.image = nil
        let exampleSchema = AttachmentSchema.list([expectedAttachment])
        medication.updateAttachments(from: exampleSchema)
        XCTAssertEqual(medication.allAttachments as? [Attachment], [expectedAttachment], "After updating the attachments the expected attachments are not the one expected")
    }

    func testPatientHasAttachments() throws {
        let patient = Patient()
        XCTAssertNil(patient.allAttachments)
        let expectedIdentifier = UUID().uuidString
        let expectedAttachment = FhirFactory.createStu3AttachmentElement()

        patient.photo = [expectedAttachment]
        patient.addAdditionalId(expectedIdentifier)

        XCTAssertEqual(expectedAttachment, patient.allAttachments?.first as? Attachment)
        XCTAssertTrue((patient as CustomIdentifierProtocol).customIdentifiers?.first?.valueString?.contains(expectedIdentifier) ?? false)

        //AttachmentSchema Test
        XCTAssertEqual(patient.schema, AttachmentSchema.list([expectedAttachment]), "The attachment schema is wrong")

        let expectedAttachmentWithId = expectedAttachment.copyWithId(UUID().uuidString)
        let notExpectedAttachment = FhirFactory.createStu3SampleImageAttachment()

        var filledAttachments: [AttachmentType] = [expectedAttachmentWithId, notExpectedAttachment]
        let schemaResult = try patient.makeFilledSchema(byMatchingTo: &filledAttachments)

        XCTAssertEqual(schemaResult, AttachmentSchema.list([expectedAttachmentWithId]), "The returned schema is wrong")
        patient.photo = nil
        let exampleSchema = AttachmentSchema.list([expectedAttachment])
        patient.updateAttachments(from: exampleSchema)
        XCTAssertEqual(patient.allAttachments as? [Attachment], [expectedAttachment], "After updating the attachments the expected attachments are not the one expected")
    }

    func testPractitionerHasAttachments() throws {
        let practitioner = Practitioner()
        XCTAssertNil(practitioner.allAttachments)
        let expectedIdentifier = UUID().uuidString
        let expectedAttachment = FhirFactory.createStu3AttachmentElement()

        practitioner.photo = [expectedAttachment]
        practitioner.addAdditionalId(expectedIdentifier)

        XCTAssertEqual(expectedAttachment, practitioner.allAttachments?.first as? Attachment)
        XCTAssertTrue((practitioner as CustomIdentifierProtocol).customIdentifiers?.first?.valueString?.contains(expectedIdentifier) ?? false)

        //AttachmentSchema Test
        XCTAssertEqual(practitioner.schema, AttachmentSchema.list([expectedAttachment]), "The attachment schema is wrong")

        let expectedAttachmentWithId = expectedAttachment.copyWithId(UUID().uuidString)
        let notExpectedAttachment = FhirFactory.createStu3SampleImageAttachment()

        var filledAttachments: [AttachmentType] = [expectedAttachmentWithId, notExpectedAttachment]
        let schemaResult = try practitioner.makeFilledSchema(byMatchingTo: &filledAttachments)

        XCTAssertEqual(schemaResult, AttachmentSchema.list([expectedAttachmentWithId]), "The returned schema is wrong")
        practitioner.photo = nil
        let exampleSchema = AttachmentSchema.list([expectedAttachment])
        practitioner.updateAttachments(from: exampleSchema)
        XCTAssertEqual(practitioner.allAttachments as? [Attachment], [expectedAttachment], "After updating the attachments the expected attachments are not the one expected")
    }

    func testObservationComponentHasAttachments() throws {
        let component = ObservationComponent()
        XCTAssertNil(component.allAttachments)
        let expectedAttachment = FhirFactory.createStu3AttachmentElement()

        component.valueAttachment = expectedAttachment

        XCTAssertEqual(expectedAttachment, component.allAttachments?.first as? Attachment)

        //AttachmentSchema Test
        XCTAssertEqual(component.schema, AttachmentSchema.single(expectedAttachment), "The attachment schema is wrong")

        let expectedAttachmentWithId = expectedAttachment.copyWithId(UUID().uuidString)
        let notExpectedAttachment = FhirFactory.createStu3SampleImageAttachment()
        var filledAttachments: [AttachmentType] = [expectedAttachmentWithId, notExpectedAttachment]
        let schemaResult = try component.makeFilledSchema(byMatchingTo: &filledAttachments)

        XCTAssertEqual(schemaResult, AttachmentSchema.single(expectedAttachmentWithId), "The returned schema is wrong")
        component.valueAttachment = nil
        let exampleSchema = AttachmentSchema.single(expectedAttachment)
        component.updateAttachments(from: exampleSchema)
        XCTAssertEqual(component.allAttachments as? [Attachment], [expectedAttachment], "After updating the attachments the expected attachments are not the one expected")
    }

    func testObservationHasAttachments() throws {
        let observation = Observation()
        XCTAssertNil(observation.allAttachments)
        let expectedIdentifier = UUID().uuidString
        let observationAttachment = FhirFactory.createStu3AttachmentElement()
        let observationComponentAttachment = FhirFactory.createStu3ImageAttachmentElement()
        let observationComponent = FhirFactory.createStu3ObservationComponentResource(valueAttachment: observationComponentAttachment)

        observation.valueAttachment = observationAttachment
        observation.component = [observationComponent]
        observation.addAdditionalId(expectedIdentifier)

        XCTAssertEqual([observationAttachment, observationComponentAttachment], observation.allAttachments as? [Attachment])
        XCTAssertTrue((observation as CustomIdentifierProtocol).customIdentifiers?.first?.valueString?.contains(expectedIdentifier) ?? false)

        //AttachmentSchema Test
        XCTAssertEqual(observation.schema, AttachmentSchema.observation(value: observationAttachment, components: [observationComponent]), "The attachment schema is wrong")

        let expectedObservationAttachmentWithId = observationAttachment.copyWithId(UUID().uuidString)
        let expectedComponentAttachmentWithId = observationComponentAttachment.copyWithId(UUID().uuidString)
        let expectedComponentWithIdInAttachment = observationComponent.copy() as! ObservationComponent // swiftlint:disable:this force_cast
        expectedComponentWithIdInAttachment.valueAttachment = expectedComponentAttachmentWithId

        let notExpectedAttachment = FhirFactory.createStu3SampleImageAttachment()

        var filledAttachments: [AttachmentType] = [expectedObservationAttachmentWithId, expectedComponentAttachmentWithId, notExpectedAttachment]
        let schemaResult = try observation.makeFilledSchema(byMatchingTo: &filledAttachments)

        let expectedSchemaResult = AttachmentSchema.observation(value: expectedObservationAttachmentWithId, components: [expectedComponentWithIdInAttachment])

        XCTAssertEqual(schemaResult, expectedSchemaResult, "The returned schema is wrong")
        observation.valueAttachment = nil
        observation.component = nil

        let exampleSchema = AttachmentSchema.observation(value: observationAttachment, components: [observationComponent])
        observation.updateAttachments(from: exampleSchema)
        XCTAssertEqual(observation.allAttachments as? [Attachment],
                       [observationAttachment, observationComponentAttachment],
                       "After updating the attachments the expected attachments are not the one expected")
    }

    func testQuestionnaireHasAttachments() throws {
        let questionnaire = Questionnaire()
        XCTAssertNil(questionnaire.allAttachments)

        let questionnaireItemAttachment1 = FhirFactory.createStu3AttachmentElement()
        let questionnaireItemAttachment2 = FhirFactory.createStu3ImageAttachmentElement()
        let nestedQuestionnaireItemAttachment3 = FhirFactory.createStu3SampleImageAttachment()
        let item1 = FhirFactory.createStu3QuestionnaireItem(initial: questionnaireItemAttachment1)
        let item2 = FhirFactory.createStu3QuestionnaireItem(initial: questionnaireItemAttachment2)
        let nestedItem3 = FhirFactory.createStu3QuestionnaireItem(initial: nestedQuestionnaireItemAttachment3)
        item2.item = [nestedItem3]
        questionnaire.item = [item1, item2]

        XCTAssertEqual([questionnaireItemAttachment1, questionnaireItemAttachment2, nestedQuestionnaireItemAttachment3], questionnaire.allAttachments as? [Attachment])

        //AttachmentSchema Test
        let expectedSchema = AttachmentSchema.questionnaire(items: [item1, item2])
        XCTAssertEqual(questionnaire.schema, expectedSchema, "The attachment schema is wrong")

        let expectedItemAttachmentWithId1 = questionnaireItemAttachment1.copyWithId(UUID().uuidString)
        let expectedItemAttachmentWithId2 = questionnaireItemAttachment2.copyWithId(UUID().uuidString)
        let expectedNestedItemAttachmentWithId3 = nestedQuestionnaireItemAttachment3.copyWithId(UUID().uuidString)

        let expectedItemWithIdInAttachment1 = item1.copy() as! QuestionnaireItem // swiftlint:disable:this force_cast
        expectedItemWithIdInAttachment1.initialAttachment = expectedItemAttachmentWithId1
        let expectedItemWithIdInAttachment2 = item2.copy() as! QuestionnaireItem // swiftlint:disable:this force_cast
        expectedItemWithIdInAttachment2.initialAttachment = expectedItemAttachmentWithId2
        let expectedItemWithIdInAttachment3 = nestedItem3.copy() as! QuestionnaireItem // swiftlint:disable:this force_cast
        expectedItemWithIdInAttachment3.initialAttachment = expectedNestedItemAttachmentWithId3
        expectedItemWithIdInAttachment2.item = [expectedItemWithIdInAttachment3]

        var filledAttachments: [AttachmentType] = [expectedItemAttachmentWithId1, expectedItemAttachmentWithId2, expectedNestedItemAttachmentWithId3]
        let schemaResult = try questionnaire.makeFilledSchema(byMatchingTo: &filledAttachments)

        let expectedSchemaResult = AttachmentSchema.questionnaire(items: [expectedItemWithIdInAttachment1, expectedItemWithIdInAttachment2])
        XCTAssertEqual(schemaResult, expectedSchemaResult, "The returned schema is wrong")

        questionnaire.item = nil
        let exampleSchema = AttachmentSchema.questionnaire(items: [item1, item2])
        questionnaire.updateAttachments(from: exampleSchema)
        XCTAssertEqual(questionnaire.allAttachments as? [Attachment],
                       [questionnaireItemAttachment1,
                        questionnaireItemAttachment2,
                        nestedQuestionnaireItemAttachment3],
                       "After updating the attachments the expected attachments are not the one expected")
    }

    func testQuestionnaireItemHasAttachments() throws {
        let mainQuestionnaireItem = QuestionnaireItem()
        XCTAssertNil(mainQuestionnaireItem.allAttachments)
        let initialAttachment = FhirFactory.createUploadedAttachmentElement()
        initialAttachment.id = nil
        let questionnaireItemAttachment1 = FhirFactory.createStu3AttachmentElement()
        let questionnaireItemAttachment2 = FhirFactory.createStu3ImageAttachmentElement()
        let nestedQuestionnaireItemAttachment3 = FhirFactory.createStu3SampleImageAttachment()
        let item1 = FhirFactory.createStu3QuestionnaireItem(initial: questionnaireItemAttachment1)
        let item2 = FhirFactory.createStu3QuestionnaireItem(initial: questionnaireItemAttachment2)
        let nestedItem3 = FhirFactory.createStu3QuestionnaireItem(initial: nestedQuestionnaireItemAttachment3)
        item2.item = [nestedItem3]
        mainQuestionnaireItem.initialAttachment = initialAttachment
        mainQuestionnaireItem.item = [item1, item2]
        XCTAssertEqual([initialAttachment, questionnaireItemAttachment1, questionnaireItemAttachment2, nestedQuestionnaireItemAttachment3], mainQuestionnaireItem.allAttachments as? [Attachment])

        //AttachmentSchema Test
        let expectedSchema = AttachmentSchema.questionnaireItem(initial: initialAttachment, nestedItems: [item1, item2])
        XCTAssertEqual(mainQuestionnaireItem.schema, expectedSchema, "The attachment schema is wrong")

        let expectedInitialAttachmentWithId = initialAttachment.copyWithId(UUID().uuidString)
        let expectedItemAttachmentWithId1 = questionnaireItemAttachment1.copyWithId(UUID().uuidString)
        let expectedItemAttachmentWithId2 = questionnaireItemAttachment2.copyWithId(UUID().uuidString)
        let expectedNestedItemAttachmentWithId3 = nestedQuestionnaireItemAttachment3.copyWithId(UUID().uuidString)

        let expectedItemWithIdInAttachment1 = item1.copy() as! QuestionnaireItem // swiftlint:disable:this force_cast
        expectedItemWithIdInAttachment1.initialAttachment = expectedItemAttachmentWithId1
        let expectedItemWithIdInAttachment2 = item2.copy() as! QuestionnaireItem // swiftlint:disable:this force_cast
        expectedItemWithIdInAttachment2.initialAttachment = expectedItemAttachmentWithId2
        let expectedItemWithIdInAttachment3 = nestedItem3.copy() as! QuestionnaireItem // swiftlint:disable:this force_cast
        expectedItemWithIdInAttachment3.initialAttachment = expectedNestedItemAttachmentWithId3
        expectedItemWithIdInAttachment2.item = [expectedItemWithIdInAttachment3]

        var filledAttachments: [AttachmentType] = [expectedInitialAttachmentWithId,
                                                   expectedItemAttachmentWithId1,
                                                   expectedItemAttachmentWithId2,
                                                   expectedNestedItemAttachmentWithId3]
        let schemaResult = try mainQuestionnaireItem.makeFilledSchema(byMatchingTo: &filledAttachments)

        let expectedSchemaResult = AttachmentSchema.questionnaireItem(initial: expectedInitialAttachmentWithId,
                                                                      nestedItems: [expectedItemWithIdInAttachment1,
                                                                                    expectedItemWithIdInAttachment2])
        XCTAssertEqual(schemaResult, expectedSchemaResult, "The returned schema is wrong")
        mainQuestionnaireItem.initialAttachment = nil
        mainQuestionnaireItem.item = nil
        let exampleSchema = AttachmentSchema.questionnaireItem(initial: initialAttachment, nestedItems: [item1, item2])
        mainQuestionnaireItem.updateAttachments(from: exampleSchema)
        XCTAssertEqual(mainQuestionnaireItem.allAttachments as? [Attachment], [initialAttachment,
                                                                               questionnaireItemAttachment1,
                                                                               questionnaireItemAttachment2,
                                                                               nestedQuestionnaireItemAttachment3], "After updating the attachments the expected attachments are not the one expected")
    }

    func testQuestionnaireResponseHasAttachments() throws {
        let questionnaireResponse = QuestionnaireResponse()
        XCTAssertNil(questionnaireResponse.allAttachments)

        let answer1Attachment = FhirFactory.createStu3AttachmentElement()
        let answer2Attachment = FhirFactory.createStu3ImageAttachmentElement()
        let answer4Attachment = FhirFactory.createStu3SampleImageAttachment()
        let answer1 = FhirFactory.createStu3QuestionnaireResponseItemAnswer(attachment: answer1Attachment)
        let answer2 = FhirFactory.createStu3QuestionnaireResponseItemAnswer(attachment: answer2Attachment)
        let answer3NestedInItem3 = FhirFactory.createStu3QuestionnaireResponseItemAnswer()
        let answer4 = FhirFactory.createStu3QuestionnaireResponseItemAnswer(attachment: answer4Attachment)

        let item3NestedInItem4 = FhirFactory.createStu3QuestionnaireResponseItem(answers: [answer3NestedInItem3])
        let item4NestedInAnswer2 = FhirFactory.createStu3QuestionnaireResponseItem(answers: [answer4], nestedItems: [item3NestedInItem4])
        answer2.item = [item4NestedInAnswer2]
        let item1 = FhirFactory.createStu3QuestionnaireResponseItem(answers: [answer1])
        let item2 = FhirFactory.createStu3QuestionnaireResponseItem(answers: [answer2])
        questionnaireResponse.item = [item1, item2]

        XCTAssertEqual([answer1Attachment, answer2Attachment, answer4Attachment], questionnaireResponse.allAttachments as? [Attachment])

        //AttachmentSchema Test
        let expectedSchema = AttachmentSchema.questionnaireResponse(items: [item1, item2])
        XCTAssertEqual(questionnaireResponse.schema, expectedSchema, "The attachment schema is wrong")

        let expectedAnswer1Attachment = answer1Attachment.copyWithId(UUID().uuidString)
        let expectedAnswer2Attachment = answer2Attachment.copyWithId(UUID().uuidString)
        let expectedAnswer4Attachment = answer4Attachment.copyWithId(UUID().uuidString)

        let expectedItem1 = item1.copy() as! QuestionnaireResponseItem // swiftlint:disable:this force_cast
        expectedItem1.answer?.first?.valueAttachment = expectedAnswer1Attachment
        let expectedItem2 = item2.copy() as! QuestionnaireResponseItem // swiftlint:disable:this force_cast
        expectedItem2.answer?.first?.valueAttachment = expectedAnswer2Attachment
        let expectedItem4 = item4NestedInAnswer2.copy() as! QuestionnaireResponseItem // swiftlint:disable:this force_cast
        expectedItem4.answer?.first?.valueAttachment = expectedAnswer4Attachment
        expectedItem2.answer?.first?.item = [expectedItem4]

        var filledAttachments: [AttachmentType] = [expectedAnswer1Attachment,
                                                   expectedAnswer2Attachment,
                                                   expectedAnswer4Attachment]
        let schemaResult = try questionnaireResponse.makeFilledSchema(byMatchingTo: &filledAttachments)

        let expectedSchemaResult = AttachmentSchema.questionnaireResponse(items: [expectedItem1, expectedItem2])
        XCTAssertEqual(schemaResult, expectedSchemaResult, "The returned schema is wrong")
        questionnaireResponse.item = nil

        let exampleSchema = AttachmentSchema.questionnaireResponse(items: [item1, item2])
        questionnaireResponse.updateAttachments(from: exampleSchema)
        XCTAssertEqual(questionnaireResponse.allAttachments as? [Attachment],
                       [answer1Attachment, answer2Attachment, answer4Attachment],
                       "After updating the attachments the expected attachments are not the one expected")
    }

    func testQuestionnaireResponseItemHasAttachments() throws {
        let mainQuestionnaireResponseItem = QuestionnaireResponseItem()
        XCTAssertNil(mainQuestionnaireResponseItem.allAttachments)

        let answer1Attachment = FhirFactory.createStu3AttachmentElement()
        let answer2Attachment = FhirFactory.createStu3ImageAttachmentElement()
        let answer4Attachment = FhirFactory.createStu3SampleImageAttachment()
        let answer1 = FhirFactory.createStu3QuestionnaireResponseItemAnswer(attachment: answer1Attachment)
        let answer2 = FhirFactory.createStu3QuestionnaireResponseItemAnswer(attachment: answer2Attachment)
        let answer3NestedInItem3 = FhirFactory.createStu3QuestionnaireResponseItemAnswer()
        let answer4 = FhirFactory.createStu3QuestionnaireResponseItemAnswer(attachment: answer4Attachment)

        let item3NestedInItem4 = FhirFactory.createStu3QuestionnaireResponseItem(answers: [answer3NestedInItem3])
        let item4NestedInAnswer2 = FhirFactory.createStu3QuestionnaireResponseItem(answers: [answer4], nestedItems: [item3NestedInItem4])
        answer2.item = [item4NestedInAnswer2]
        let item1 = FhirFactory.createStu3QuestionnaireResponseItem(answers: [answer1])
        let item2 = FhirFactory.createStu3QuestionnaireResponseItem(answers: [answer2])
        mainQuestionnaireResponseItem.item = [item1, item2]

        XCTAssertEqual([answer1Attachment, answer2Attachment, answer4Attachment], mainQuestionnaireResponseItem.allAttachments as? [Attachment])

        //AttachmentSchema Test
        let expectedSchema = AttachmentSchema.questionnaireResponseItem(answers: nil, nestedItems: [item1, item2])
        XCTAssertEqual(mainQuestionnaireResponseItem.schema, expectedSchema, "The attachment schema is wrong")

        let expectedAnswer1Attachment = answer1Attachment.copyWithId(UUID().uuidString)
        let expectedAnswer2Attachment = answer2Attachment.copyWithId(UUID().uuidString)
        let expectedAnswer4Attachment = answer4Attachment.copyWithId(UUID().uuidString)

        let expectedItem1 = item1.copy() as! QuestionnaireResponseItem // swiftlint:disable:this force_cast
        expectedItem1.answer?.first?.valueAttachment = expectedAnswer1Attachment
        let expectedItem2 = item2.copy() as! QuestionnaireResponseItem // swiftlint:disable:this force_cast
        expectedItem2.answer?.first?.valueAttachment = expectedAnswer2Attachment
        let expectedItem4 = item4NestedInAnswer2.copy() as! QuestionnaireResponseItem // swiftlint:disable:this force_cast
        expectedItem4.answer?.first?.valueAttachment = expectedAnswer4Attachment
        expectedItem2.answer?.first?.item = [expectedItem4]

        var filledAttachments: [AttachmentType] = [expectedAnswer1Attachment,
                                                   expectedAnswer2Attachment,
                                                   expectedAnswer4Attachment]
        let schemaResult = try mainQuestionnaireResponseItem.makeFilledSchema(byMatchingTo: &filledAttachments)

        let expectedSchemaResult = AttachmentSchema.questionnaireResponseItem(answers: nil, nestedItems: [expectedItem1, expectedItem2])
        XCTAssertEqual(schemaResult, expectedSchemaResult, "The returned schema is wrong")
        mainQuestionnaireResponseItem.item = nil

        let exampleSchema = AttachmentSchema.questionnaireResponseItem(answers: nil, nestedItems: [item1, item2])
        mainQuestionnaireResponseItem.updateAttachments(from: exampleSchema)
        XCTAssertEqual(mainQuestionnaireResponseItem.allAttachments as? [Attachment],
                       [answer1Attachment, answer2Attachment, answer4Attachment],
                       "After updating the attachments the expected attachments are not the one expected")
    }

    func testQuestionnaireResponseItemAnswerHasAttachments() throws {
        let valueAttachment = FhirFactory.createUploadedAttachmentElement()
        valueAttachment.id = nil
        let questionnaireResponseItem1Answer1Attachment = FhirFactory.createStu3AttachmentElement()
        let questionnaireResponseItem1Answer2Attachment = FhirFactory.createStu3ImageAttachmentElement()
        let questionnaireResponseItem1Item1Answer1Attachment = FhirFactory.createStu3SampleImageAttachment()

        let questionnaireResponseItem1Answer1 = FhirFactory.createStu3QuestionnaireResponseItemAnswer(attachment: questionnaireResponseItem1Answer1Attachment)
        let questionnaireResponseItem1Answer2 = FhirFactory.createStu3QuestionnaireResponseItemAnswer(attachment: questionnaireResponseItem1Answer2Attachment)
        let questionnaireResponseItem1Item1Answer1 = FhirFactory.createStu3QuestionnaireResponseItemAnswer(attachment: questionnaireResponseItem1Item1Answer1Attachment)
        let questionnaireResponseItem1Item1 = FhirFactory.createStu3QuestionnaireResponseItem(answers: [questionnaireResponseItem1Item1Answer1])

        let item1 = FhirFactory.createStu3QuestionnaireResponseItem(answers: [
            questionnaireResponseItem1Answer1,
            questionnaireResponseItem1Answer2
        ], nestedItems: [questionnaireResponseItem1Item1])
        let mainQuestionnaireResponseItemAnswer = QuestionnaireResponseItemAnswer()
        XCTAssertNil(mainQuestionnaireResponseItemAnswer.allAttachments)
        mainQuestionnaireResponseItemAnswer.valueAttachment = valueAttachment
        mainQuestionnaireResponseItemAnswer.item = [item1]
        XCTAssertEqual(mainQuestionnaireResponseItemAnswer.allAttachments as? [Attachment],
                       [valueAttachment,
                        questionnaireResponseItem1Answer1Attachment,
                        questionnaireResponseItem1Answer2Attachment,
                        questionnaireResponseItem1Item1Answer1Attachment])

        //AttachmentSchema Test
        let expectedSchema = AttachmentSchema.questionnaireResponseItemAnswer(value: valueAttachment, nestedItems: [item1])
        XCTAssertEqual(mainQuestionnaireResponseItemAnswer.schema, expectedSchema, "The attachment schema is wrong")

        let expectedValueAttachmentWithId = valueAttachment.copyWithId(UUID().uuidString)
        let expectedItem1Answer1AttachmentWithId = questionnaireResponseItem1Answer1Attachment.copyWithId(UUID().uuidString)
        let expectedItem1Answer2AttachmentWithId = questionnaireResponseItem1Answer2Attachment.copyWithId(UUID().uuidString)
        let expectedItem1Item1Answer1AttachmentWithId = questionnaireResponseItem1Item1Answer1Attachment.copyWithId(UUID().uuidString)

        let expectedFilledItem = item1.copy() as! QuestionnaireResponseItem // swiftlint:disable:this force_cast
        expectedFilledItem.answer?[0].valueAttachment = expectedItem1Answer1AttachmentWithId
        expectedFilledItem.answer?[1].valueAttachment = expectedItem1Answer2AttachmentWithId
        expectedFilledItem.item?[0].answer?[0].valueAttachment = expectedItem1Item1Answer1AttachmentWithId

        var filledAttachments: [AttachmentType] = [expectedValueAttachmentWithId,
                                                   expectedItem1Answer1AttachmentWithId,
                                                   expectedItem1Answer2AttachmentWithId,
                                                   expectedItem1Item1Answer1AttachmentWithId]
        let schemaResult = try mainQuestionnaireResponseItemAnswer.makeFilledSchema(byMatchingTo: &filledAttachments)

        let expectedSchemaResult = AttachmentSchema.questionnaireResponseItemAnswer(value: expectedValueAttachmentWithId,
                                                                                    nestedItems: [expectedFilledItem])
        XCTAssertEqual(schemaResult, expectedSchemaResult, "The returned schema is wrong")
        mainQuestionnaireResponseItemAnswer.valueAttachment = nil
        mainQuestionnaireResponseItemAnswer.item = nil
        let exampleSchema = AttachmentSchema.questionnaireResponseItemAnswer(value: valueAttachment, nestedItems: [item1])
        mainQuestionnaireResponseItemAnswer.updateAttachments(from: exampleSchema)
        XCTAssertEqual(mainQuestionnaireResponseItemAnswer.allAttachments as? [Attachment], [valueAttachment,
                                                                                             questionnaireResponseItem1Answer1Attachment,
                                                                                             questionnaireResponseItem1Answer2Attachment,
                                                                                             questionnaireResponseItem1Item1Answer1Attachment],
                       "After updating the attachments the expected attachments are not the one expected")
    }
}
